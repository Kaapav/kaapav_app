// lib/services/api/api_client.dart
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http_parser/http_parser.dart';
import '../../config/constants.dart';
import '../../utils/logger.dart';
import 'api_interceptors.dart';

// ═══════════════════════════════════════════════════════════
// API ERROR
// ═══════════════════════════════════════════════════════════

class ApiError implements Exception {
  final String message;
  final int? status;
  final String code;
  final dynamic details;
  final DateTime timestamp;

  ApiError(this.message, {this.status, this.code = 'UNKNOWN', this.details})
      : timestamp = DateTime.now();

  bool get isAuth => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isRateLimit => status == 429;
  bool get isServer => (status ?? 0) >= 500;
  bool get isNetwork => code == 'NETWORK_ERROR';
  bool get isTimeout => code == 'TIMEOUT';
  bool get isOffline => code == 'OFFLINE';
  bool get isCircuitOpen => code == 'CIRCUIT_OPEN';
  bool get isCancelled => code == 'CANCELLED';

  String get displayMessage {
    if (isOffline) return 'You are offline. Check your connection.';
    if (isTimeout) return 'Request timed out. Try again.';
    if (isCircuitOpen) return 'Service temporarily unavailable.';
    if (isAuth) return 'Session expired. Please login again.';
    if (isRateLimit) return 'Too many requests. Wait a moment.';
    if (isServer) return 'Server error. Try again later.';
    if (isNetwork) return 'Network error. Check your connection.';
    return message;
  }

  @override
  String toString() => 'ApiError($code): $message [status: $status]';
}

// ═══════════════════════════════════════════════════════════
// CIRCUIT BREAKER
// ═══════════════════════════════════════════════════════════

enum _CircuitState { closed, open, halfOpen }

class _CircuitBreaker {
  // ✅ Fix: removed unused named params, use constants directly
  final int threshold = AppConstants.circuitBreakerThreshold;
  final Duration timeout = AppConstants.circuitBreakerTimeout;
  int _failures = 0;
  _CircuitState _state = _CircuitState.closed;
  DateTime? _nextAttempt;
  int _halfOpenSuccesses = 0;

  void recordSuccess() {
    if (_state == _CircuitState.halfOpen) {
      _halfOpenSuccesses++;
      if (_halfOpenSuccesses >= 2) {
        _reset();
        AppLogger.info('⚡ Circuit CLOSED — recovered');
      }
    }
    _failures = 0;
  }

  void recordFailure() {
    _failures++;
    _halfOpenSuccesses = 0;
    if (_failures >= threshold && _state == _CircuitState.closed) {
      _state = _CircuitState.open;
      _nextAttempt = DateTime.now().add(timeout);
      AppLogger.error('🔴 Circuit OPEN — $_failures failures');
    }
  }

  bool get canRequest {
    if (_state == _CircuitState.closed) return true;
    if (_state == _CircuitState.open &&
        _nextAttempt != null &&
        DateTime.now().isAfter(_nextAttempt!)) {
      _state = _CircuitState.halfOpen;
      _halfOpenSuccesses = 0;
      return true;
    }
    return _state == _CircuitState.halfOpen;
  }

  void _reset() {
    _failures = 0;
    _state = _CircuitState.closed;
    _nextAttempt = null;
    _halfOpenSuccesses = 0;
  }

  void forceReset() => _reset();
}

// ═══════════════════════════════════════════════════════════
// RESPONSE CACHE
// ═══════════════════════════════════════════════════════════

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  _CacheEntry(this.data, Duration ttl) : expiry = DateTime.now().add(ttl);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class _ResponseCache {
  // ✅ Fix: use collection literal instead of constructor
  final _cache = <String, _CacheEntry>{};
  Timer? _cleanup;

  _ResponseCache() {
    _cleanup = Timer.periodic(const Duration(minutes: 2), (_) {
      _cache.removeWhere((_, e) => e.isExpired);
    });
  }

  dynamic get(String url) {
    final entry = _cache[url];
    if (entry == null || entry.isExpired) {
      _cache.remove(url);
      return null;
    }
    return entry.data;
  }

  void set(String url, dynamic data, Duration ttl) {
    if (_cache.length >= 100) _cache.remove(_cache.keys.first);
    _cache[url] = _CacheEntry(data, ttl);
  }

  void invalidate(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }

  void clear() => _cache.clear();

  void dispose() {
    _cleanup?.cancel();
    _cache.clear();
  }
}

// ═══════════════════════════════════════════════════════════
// REQUEST DEDUPLICATOR
// ═══════════════════════════════════════════════════════════

class _Deduplicator {
  final _inflight = <String, Future<Response>>{};

  String _key(String method, String url, dynamic body) {
    if (body == null) return '$method:$url';
    final hash = md5.convert(utf8.encode(body.toString())).toString();
    return '$method:$url:$hash';
  }

  Future<Response>? get(String method, String url, [dynamic body]) {
    if (method != 'GET') return null;
    return _inflight[_key(method, url, body)];
  }

  void register(String method, String url, Future<Response> future, [dynamic body]) {
    if (method != 'GET') return;
    final key = _key(method, url, body);
    _inflight[key] = future;
    future.whenComplete(() => _inflight.remove(key));
  }

  void clear() => _inflight.clear();
  int get count => _inflight.length;
}

// ═══════════════════════════════════════════════════════════
// CONCURRENCY LIMITER
// ═══════════════════════════════════════════════════════════

class _Limiter {
  // ✅ Fix: removed unused named param
  final int max = AppConstants.maxConcurrentRequests;
  int _running = 0;
  final _queue = Queue<Completer<void>>();

  Future<void> acquire() async {
    if (_running < max) {
      _running++;
      return;
    }
    final c = Completer<void>();
    _queue.add(c);
    await c.future;
  }

  void release() {
    _running--;
    if (_queue.isNotEmpty) {
      _running++;
      _queue.removeFirst().complete();
    }
  }
}

// ═══════════════════════════════════════════════════════════
// OFFLINE QUEUE
// ═══════════════════════════════════════════════════════════

// ✅ Fix: made public so OfflineQueue public methods can reference it
class OfflineRequest {
  final String endpoint;
  final String method;
  final dynamic body;
  int attempts;
  // ✅ Fix: removed unused optional param
  OfflineRequest(this.endpoint, this.method, this.body) : attempts = 0;
}

class OfflineQueue {
  final _queue = Queue<OfflineRequest>();
  bool isProcessing = false;

  void enqueue(String endpoint, String method, dynamic body) {
    _queue.add(OfflineRequest(endpoint, method, body));
    AppLogger.info('📴 Queued: $method $endpoint');
  }

  int get count => _queue.length;
  bool get isEmpty => _queue.isEmpty;
  OfflineRequest? dequeue() => _queue.isEmpty ? null : _queue.removeFirst();

  void requeue(OfflineRequest req) {
    req.attempts++;
    _queue.addLast(req);
  }

  void clear() => _queue.clear();
}

// ═══════════════════════════════════════════════════════════
// API METRICS
// ═══════════════════════════════════════════════════════════

class ApiMetrics {
  int total = 0;
  int success = 0;
  int failed = 0;
  int cached = 0;
  int retried = 0;
  int offlineQueued = 0;

  Map<String, int> toJson() => {
        'total': total, 'success': success, 'failed': failed,
        'cached': cached, 'retried': retried, 'offlineQueued': offlineQueued,
      };

  void reset() {
    total = 0; success = 0; failed = 0;
    cached = 0; retried = 0; offlineQueued = 0;
  }
}

// ═══════════════════════════════════════════════════════════
// MAIN API CLIENT
// ═══════════════════════════════════════════════════════════

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  final _circuit = _CircuitBreaker();
  final _cache = _ResponseCache();
  final _dedup = _Deduplicator();
  final _limiter = _Limiter();
  final offlineQueue = OfflineQueue();
  final metrics = ApiMetrics();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  StreamSubscription? _connectivitySub;
  final _onlineController = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _onlineController.stream;

  String? _tokenCache;
  DateTime? _tokenCacheExpiry;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Client-Platform': 'flutter',
        'X-Client-Version': AppConstants.appVersion,
      },
      validateStatus: (_) => true,
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(this),
      LoggingInterceptor(),
    ]);

    _setupConnectivity();
    AppLogger.info('🏰 API Client → ${AppConstants.apiBaseUrl}');
  }

  void _setupConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((dynamic result) {
      final wasOffline = !_isOnline;
      final List<ConnectivityResult> resultList;
      if (result is List) {
        resultList = List<ConnectivityResult>.from(result);
      } else if (result is ConnectivityResult) {
        resultList = [result];
      } else {
        resultList = [];
      }
      _isOnline = resultList.isNotEmpty &&
                  resultList.any((r) => r != ConnectivityResult.none);
      _onlineController.add(_isOnline);
      if (_isOnline && wasOffline) {
        AppLogger.info('🌐 Back online');
        _circuit.forceReset();
        processOfflineQueue();
      }
    });
  }

  String? get cachedToken {
    if (_tokenCacheExpiry != null && DateTime.now().isAfter(_tokenCacheExpiry!)) {
      _tokenCache = null;
      _tokenCacheExpiry = null;
    }
    return _tokenCache;
  }

  void setCachedToken(String? token) {
    _tokenCache = token;
    _tokenCacheExpiry = token != null ? DateTime.now().add(const Duration(minutes: 5)) : null;
  }

  void clearTokenCache() {
    _tokenCache = null;
    _tokenCacheExpiry = null;
  }

  String getMimeTypeFromExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'svg': return 'image/svg+xml';
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt': return 'text/plain';
      case 'csv': return 'text/csv';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'avi': return 'video/x-msvideo';
      case 'webm': return 'video/webm';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'ogg': return 'audio/ogg';
      case 'm4a': return 'audio/mp4';
      case 'zip': return 'application/zip';
      default: return 'application/octet-stream';
    }
  }

  Future<Response> request(
    String endpoint, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool useCache = true,
    Duration cacheTTL = AppConstants.cacheTTL,
    bool skipAuth = false,
    CancelToken? cancelToken,
  }) async {
    final fullUrl = '$endpoint${_qs(queryParameters)}';
    metrics.total++;

    if (!_circuit.canRequest) {
      metrics.failed++;
      throw ApiError('Service temporarily unavailable', status: 503, code: 'CIRCUIT_OPEN');
    }

    if (!_isOnline) {
      if (method != 'GET') {
        offlineQueue.enqueue(endpoint, method, data);
        metrics.offlineQueued++;
        return Response(
          requestOptions: RequestOptions(path: endpoint),
          data: {'success': false, 'offline': true, 'queued': true},
          statusCode: 0,
        );
      }
      final cached = _cache.get(fullUrl);
      if (cached != null) {
        metrics.cached++;
        return Response(requestOptions: RequestOptions(path: endpoint), data: cached, statusCode: 200);
      }
      metrics.failed++;
      throw ApiError('You are offline', code: 'OFFLINE');
    }

    if (useCache && method == 'GET') {
      final cached = _cache.get(fullUrl);
      if (cached != null) {
        metrics.cached++;
        return Response(requestOptions: RequestOptions(path: endpoint), data: cached, statusCode: 200);
      }
    }

    final existing = _dedup.get(method, fullUrl, data);
    if (existing != null) return existing;

    final future = _executeWithRetry(
      endpoint: endpoint, fullUrl: fullUrl, method: method, data: data,
      queryParameters: queryParameters, skipAuth: skipAuth, cancelToken: cancelToken,
      cacheTTL: cacheTTL, useCache: useCache,
      retriesLeft: AppConstants.maxRetries,
    );

    _dedup.register(method, fullUrl, future, data);
    return future;
  }

  Future<Response> _executeWithRetry({
    required String endpoint,
    required String fullUrl,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required bool skipAuth,
    CancelToken? cancelToken,
    required Duration cacheTTL,
    required bool useCache,
    required int retriesLeft,
  }) async {
    await _limiter.acquire();

    try {
      final response = await _dio.request(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, extra: {'skipAuth': skipAuth}),
        cancelToken: cancelToken,
      );

      final status = response.statusCode ?? 0;

      if (status >= 200 && status < 300) {
        _circuit.recordSuccess();
        metrics.success++;
        if (method == 'GET' && useCache) _cache.set(fullUrl, response.data, cacheTTL);
        if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) _invalidateRelated(endpoint);
        return response;
      }

      if (status == 401) {
        metrics.failed++;
        throw ApiError(_extractError(response.data) ?? 'Unauthorized', status: 401, code: 'AUTH_ERROR');
      }

      if (status == 429 && retriesLeft > 0) {
        _circuit.recordFailure();
        metrics.retried++;
        final wait = int.tryParse(response.headers.value('retry-after') ?? '60') ?? 60;
        await Future.delayed(Duration(seconds: wait));
        return _executeWithRetry(
          endpoint: endpoint, fullUrl: fullUrl, method: method, data: data,
          queryParameters: queryParameters, skipAuth: skipAuth, cancelToken: cancelToken,
          cacheTTL: cacheTTL, useCache: useCache, retriesLeft: retriesLeft - 1,
        );
      }

      if (status >= 500 && retriesLeft > 0) {
        _circuit.recordFailure();
        metrics.retried++;
        await Future.delayed(_backoff(AppConstants.maxRetries - retriesLeft));
        return _executeWithRetry(
          endpoint: endpoint, fullUrl: fullUrl, method: method, data: data,
          queryParameters: queryParameters, skipAuth: skipAuth, cancelToken: cancelToken,
          cacheTTL: cacheTTL, useCache: useCache, retriesLeft: retriesLeft - 1,
        );
      }

      _circuit.recordFailure();
      metrics.failed++;
      throw ApiError(_extractError(response.data) ?? 'Request failed ($status)', status: status, code: 'HTTP_$status');

    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw ApiError('Request cancelled', code: 'CANCELLED');
      }
      if (_isRetryable(e) && retriesLeft > 0) {
        _circuit.recordFailure();
        metrics.retried++;
        await Future.delayed(_backoff(AppConstants.maxRetries - retriesLeft));
        return _executeWithRetry(
          endpoint: endpoint, fullUrl: fullUrl, method: method, data: data,
          queryParameters: queryParameters, skipAuth: skipAuth, cancelToken: cancelToken,
          cacheTTL: cacheTTL, useCache: useCache, retriesLeft: retriesLeft - 1,
        );
      }
      _circuit.recordFailure();
      metrics.failed++;
      if (_isTimeout(e)) throw ApiError('Request timed out', code: 'TIMEOUT');
      throw ApiError(e.message ?? 'Network error', code: 'NETWORK_ERROR');
    } on ApiError {
      rethrow;
    } finally {
      _limiter.release();
    }
  }

  Future<Response> uploadFile(
    String endpoint,
    File file, {
    String fieldName = 'file',
    Map<String, String>? fields,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final mimeType = getMimeTypeFromExtension(fileName);
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
        if (fields != null) ...fields,
      });
      final response = await request(endpoint, method: 'POST', data: formData, useCache: false, cancelToken: cancelToken);
      AppLogger.success('✅ Upload complete: ${response.data?['url']}');
      return response;
    } catch (e) {
      AppLogger.error('❌ File upload failed', e);
      rethrow;
    }
  }

  Future<Response> get(String endpoint, {
    Map<String, dynamic>? queryParameters, bool useCache = true,
    Duration cacheTTL = AppConstants.cacheTTL, CancelToken? cancelToken,
  }) => request(endpoint, queryParameters: queryParameters, useCache: useCache, cacheTTL: cacheTTL, cancelToken: cancelToken);

  Future<Response> post(String endpoint, {dynamic data, bool skipAuth = false, CancelToken? cancelToken}) =>
      request(endpoint, method: 'POST', data: data, useCache: false, skipAuth: skipAuth, cancelToken: cancelToken);

  Future<Response> put(String endpoint, {dynamic data, CancelToken? cancelToken}) =>
      request(endpoint, method: 'PUT', data: data, useCache: false, cancelToken: cancelToken);

  Future<Response> patch(String endpoint, {dynamic data, CancelToken? cancelToken}) =>
      request(endpoint, method: 'PATCH', data: data, useCache: false, cancelToken: cancelToken);

  Future<Response> delete(String endpoint, {CancelToken? cancelToken}) =>
      request(endpoint, method: 'DELETE', useCache: false, cancelToken: cancelToken);

  Future<void> processOfflineQueue() async {
    if (offlineQueue.isProcessing || offlineQueue.isEmpty) return;
    offlineQueue.isProcessing = true;
    AppLogger.info('📤 Processing ${offlineQueue.count} queued requests');
    try {
      while (!offlineQueue.isEmpty && _isOnline) {
        final req = offlineQueue.dequeue();
        if (req == null) break;
        if (req.attempts >= 5) continue;
        try {
          await request(req.endpoint, method: req.method, data: req.body);
          AppLogger.info('✅ Processed: ${req.method} ${req.endpoint}');
        } catch (_) {
          offlineQueue.requeue(req);
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      offlineQueue.isProcessing = false;
    }
  }

  void clearCache() => _cache.clear();
  void invalidateCache(String pattern) => _cache.invalidate(pattern);

  Map<String, dynamic> get health => {
        'online': _isOnline,
        'offlineQueue': offlineQueue.count,
        'inflight': _dedup.count,
        'metrics': metrics.toJson(),
      };

  String? _extractError(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) return (data['error'] ?? data['message'])?.toString();
    return null;
  }

  Duration _backoff(int attempt) {
    final ms = 1000 * (1 << attempt);
    final jitter = (ms * 0.3 * Random().nextDouble()).toInt();
    return Duration(milliseconds: min(ms + jitter, AppConstants.retryMaxDelay.inMilliseconds));
  }

  bool _isRetryable(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError;

  bool _isTimeout(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  String _qs(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    return '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  void _invalidateRelated(String endpoint) {
    final parts = endpoint.split('/');
    if (parts.length >= 3) _cache.invalidate(parts.take(3).join('/'));
  }

  void dispose() {
    _connectivitySub?.cancel();
    _onlineController.close();
    _cache.dispose();
    _dedup.clear();
    _dio.close();
    _instance = null;
  }
}