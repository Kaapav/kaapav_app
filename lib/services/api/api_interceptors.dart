// lib/services/api/api_interceptors.dart

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';
import '../../utils/logger.dart';
import 'api_client.dart';
	

// ═══════════════════════════════════════════════════════════
// AUTH INTERCEPTOR
// ═══════════════════════════════════════════════════════════

class AuthInterceptor extends Interceptor {
  final ApiClient _client;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _isRefreshing = false;
  final _pendingRequests = <_QueuedRequest>[];

  AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] == true || _isAuthPath(options.path)) {
      return handler.next(options);
    }

    try {
      var token = _client.cachedToken;

      if (token == null) {
        token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) _client.setCachedToken(token);
      }

      if (token == null) return handler.next(options);

      if (_isExpiringSoon(token)) {
        final refreshed = await _doRefresh();
        if (refreshed != null) token = refreshed;
      }

      options.headers['Authorization'] = 'Bearer $token';
    } catch (e) {
      AppLogger.error('Auth interceptor: $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        _isAuthPath(err.requestOptions.path) ||
        err.requestOptions.extra['_retried'] == true) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      final completer = Completer<Response>();
      _pendingRequests.add(_QueuedRequest(err.requestOptions, completer));
      try {
        return handler.resolve(await completer.future);
      } catch (_) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    try {
      final newToken = await _doRefresh();

      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        err.requestOptions.extra['_retried'] = true;
        final response = await _freshDio().fetch(err.requestOptions);

        // ✅ Fix: added curly braces to for loops
        for (final q in _pendingRequests) {
          q.options.headers['Authorization'] = 'Bearer $newToken';
          q.options.extra['_retried'] = true;
          _freshDio().fetch(q.options).then(q.completer.complete, onError: q.completer.completeError);
        }
        _pendingRequests.clear();
        return handler.resolve(response);
      }

      // ✅ Fix: added curly braces to for loops
      for (final q in _pendingRequests) {
        q.completer.completeError(err);
      }
      _pendingRequests.clear();
      _client.clearTokenCache();
      await _clearStored();
    } catch (e) {
      for (final q in _pendingRequests) {
        q.completer.completeError(e);
      }
      _pendingRequests.clear();
      _client.clearTokenCache();
      await _clearStored();
    } finally {
      _isRefreshing = false;
    }

    handler.next(err);
  }

  Future<String?> _doRefresh() async {
    try {
      final current = _client.cachedToken ?? await _storage.read(key: AppConstants.tokenKey);
      if (current == null) return null;

      final response = await _freshDio().post(
        ApiEndpoints.refresh,
        options: Options(headers: {'Authorization': 'Bearer $current'}),
      );

      if (response.statusCode == 200 && response.data is Map && response.data['token'] != null) {
        final newToken = response.data['token'] as String;
        await _storage.write(key: AppConstants.tokenKey, value: newToken);
        if (response.data['expiresAt'] != null) {
          await _storage.write(key: AppConstants.tokenExpiryKey, value: response.data['expiresAt'].toString());
        }
        _client.setCachedToken(newToken);
        AppLogger.info('🔑 Token refreshed');
        return newToken;
      }
    } catch (e) {
      AppLogger.error('Token refresh failed: $e');
    }
    return null;
  }

  bool _isExpiringSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      if (payload['exp'] == null) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
      return expiry.isBefore(DateTime.now().add(AppConstants.tokenRefreshBuffer));
    } catch (_) {
      return true;
    }
  }

  bool _isAuthPath(String path) =>
      path.contains('/auth/login') || path.contains('/auth/register') || path.contains('/auth/refresh');

  Dio _freshDio() => Dio(BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (_) => true,
      ));

  Future<void> _clearStored() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.tokenExpiryKey);
  }
}

class _QueuedRequest {
  final RequestOptions options;
  final Completer<Response> completer;
  _QueuedRequest(this.options, this.completer);
}

// ═══════════════════════════════════════════════════════════
// LOGGING INTERCEPTOR
// ═══════════════════════════════════════════════════════════

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.network(options.method, options.uri.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.network(
      response.requestOptions.method,
      response.requestOptions.uri.toString(),
      statusCode: response.statusCode,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error('${err.requestOptions.method} ${err.requestOptions.path} → ${err.type.name}');
    handler.next(err);
  }
}