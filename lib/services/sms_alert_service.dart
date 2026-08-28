// lib/services/sms_alert_service.dart
// ═══════════════════════════════════════════════════════════════
// ON-DEVICE SMS, RAZORPAY, SHIPROCKET & OTP PARSER SERVICE
// Listens to Android SMS BroadcastReceiver & MethodChannel
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sms_alert_model.dart';
import '../utils/logger.dart';

class SmsAlertService {
  static SmsAlertService? _instance;
  static SmsAlertService get instance {
    _instance ??= SmsAlertService._();
    return _instance!;
  }

  SmsAlertService._();

  static const MethodChannel _methodChannel =
      MethodChannel('com.kaapav.app/sms_reader');
  static const EventChannel _eventChannel =
      EventChannel('com.kaapav.app/sms_stream');

  static const String _storageKey = 'kaapav_saved_sms_alerts';

  StreamSubscription? _streamSubscription;
  final List<SmsAlert> _alerts = [];
  final _alertsController = StreamController<List<SmsAlert>>.broadcast();

  Stream<List<SmsAlert>> get alertsStream => _alertsController.stream;
  List<SmsAlert> get alerts => List.unmodifiable(_alerts);

  bool _isInitialized = false;

  // ─────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadSavedAlerts();

    // Check permission & start listening
    final hasPermission = await checkPermission();
    if (hasPermission) {
      _startListening();
      await fetchRecentSms();
    }
  }

  Future<bool> checkPermission() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('hasSmsPermission');
      return res ?? false;
    } catch (_) {
      final status = await Permission.sms.status;
      return status.isGranted;
    }
  }

  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      _startListening();
      await fetchRecentSms();
      return true;
    }
    return false;
  }

  void _startListening() {
    _streamSubscription?.cancel();
    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final map = Map<String, dynamic>.from(event);
          final sender = '${map['sender'] ?? ''}';
          final body = '${map['body'] ?? ''}';
          final timestamp = map['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : DateTime.now();

          final parsed = parseSms(sender: sender, body: body, timestamp: timestamp);
          if (parsed != null) {
            _addAlert(parsed);
          }
        }
      },
      onError: (err) {
        AppLogger.error('SmsAlertService stream error: $err');
      },
    );
  }

  Future<void> fetchRecentSms({int limit = 40}) async {
    try {
      final List<dynamic>? raw =
          await _methodChannel.invokeMethod('getRecentSms', {'limit': limit});
      if (raw == null) return;

      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final sender = '${map['sender'] ?? ''}';
          final body = '${map['body'] ?? ''}';
          final timestamp = map['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : DateTime.now();

          final parsed = parseSms(sender: sender, body: body, timestamp: timestamp);
          if (parsed != null) {
            _addAlert(parsed, notify: false);
          }
        }
      }
      _notifyAndSave();
    } catch (e) {
      AppLogger.warning('Could not fetch recent SMS: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BATTLE-TESTED REGEX PARSER FOR RAZORPAY, SHIPROCKET & OTP
  // ─────────────────────────────────────────────────────────────

  SmsAlert? parseSms({
    required String sender,
    required String body,
    required DateTime timestamp,
  }) {
    if (body.trim().isEmpty) return null;

    final lower = body.toLowerCase();
    final lowerSender = sender.toLowerCase();

    final id = '${sender.hashCode}_${timestamp.millisecondsSinceEpoch}_${body.length}';

    // 1. RAZORPAY / BANK PAYMENT DETECTION
    if (lowerSender.contains('rzr') ||
        lowerSender.contains('razor') ||
        lower.contains('razorpay') ||
        (lower.contains('received') && (lower.contains('rs.') || lower.contains('inr') || lower.contains('₹'))) ||
        (lower.contains('credited') && (lower.contains('rs.') || lower.contains('inr') || lower.contains('₹')))) {
      
      final amount = _extractAmount(body);
      final paymentId = _extractRegex(body, r'(pay_[a-zA-Z0-9]{10,24}|pl_[a-zA-Z0-9]{10,24}|rfnd_[a-zA-Z0-9]{10,24}|UPI\/[0-9]{10,14})');

      String title = 'Payment Received';
      if (lower.contains('refund')) {
        title = 'Razorpay Refund Update';
      } else if (lower.contains('payout') || lower.contains('settled')) {
        title = 'Razorpay Settlement';
      } else if (amount != null) {
        title = 'Payment Received: ₹${amount.toStringAsFixed(0)}';
      }

      return SmsAlert(
        id: id,
        type: 'payment',
        sender: sender,
        title: title,
        body: body,
        amount: amount,
        referenceId: paymentId,
        timestamp: timestamp,
      );
    }

    // 2. SHIPROCKET & COURIER LOGISTICS DETECTION
    if (lowerSender.contains('shprkt') ||
        lowerSender.contains('shiprocket') ||
        lowerSender.contains('dlhvry') ||
        lowerSender.contains('delhivery') ||
        lowerSender.contains('bludrt') ||
        lower.contains('shiprocket') ||
        lower.contains('out for delivery') ||
        lower.contains('awb') ||
        lower.contains('waybill') ||
        lower.contains('shipment tracking')) {

      final awb = _extractRegex(body, r'\b(?:awb|waybill|tracking\s*(?:no|id|number)?|id)[\s:#-]*([0-9A-Za-z]{7,20})\b', group: 1) ??
          _extractRegex(body, r'\b([0-9]{9,16})\b');

      String title = 'Shiprocket Update';
      if (lower.contains('out for delivery')) {
        title = '🚚 Out for Delivery';
      } else if (lower.contains('delivered')) {
        title = '✅ Shipment Delivered';
      } else if (lower.contains('pickup')) {
        title = '📦 Courier Pickup Update';
      } else if (lower.contains('ndr') || lower.contains('failed') || lower.contains('undelivered')) {
        title = '⚠️ Delivery Exception / NDR';
      }

      final trackingUrl = awb != null
          ? 'https://www.shiprocket.in/shipment-tracking/?id=$awb'
          : _extractUrl(body);

      return SmsAlert(
        id: id,
        type: 'shipping',
        sender: sender,
        title: title,
        body: body,
        referenceId: awb,
        trackingUrl: trackingUrl,
        timestamp: timestamp,
      );
    }

    // 3. OTP & 2FA VERIFICATION CODE DETECTION
    if (lower.contains('otp') ||
        lower.contains('verification code') ||
        lower.contains('passcode') ||
        lower.contains('one time password') ||
        lower.contains('secret code') ||
        lower.contains('login code')) {

      final otp = _extractOtp(body);
      if (otp != null && otp.isNotEmpty) {
        String serviceName = 'Verification OTP';
        if (lower.contains('razorpay')) {
          serviceName = 'Razorpay Login OTP';
        } else if (lower.contains('shiprocket')) {
          serviceName = 'Shiprocket OTP';
        } else if (lower.contains('whatsapp')) {
          serviceName = 'WhatsApp Code';
        } else if (lower.contains('bank') ||
            lowerSender.contains('bnk') ||
            lowerSender.contains('hdfc') ||
            lowerSender.contains('sbi') ||
            lowerSender.contains('icici') ||
            lowerSender.contains('axis')) {
          serviceName = 'Bank Transaction OTP';
        }

        return SmsAlert(
          id: id,
          type: 'otp',
          sender: sender,
          title: serviceName,
          body: body,
          otp: otp,
          timestamp: timestamp,
          expiresAt: timestamp.add(const Duration(minutes: 10)),
        );
      }
    }

    // Default to general if sender looks like business or bank
    if (lowerSender.contains('kaapav') || lower.contains('kaapav')) {
      return SmsAlert(
        id: id,
        type: 'general',
        sender: sender,
        title: 'KAAPAV Alert',
        body: body,
        timestamp: timestamp,
      );
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // INGEST WHATSAPP / EXTERNAL MESSAGES
  // ─────────────────────────────────────────────────────────────

  void ingestMessage({
    required String sender,
    required String body,
    required DateTime timestamp,
  }) {
    final parsed = parseSms(sender: sender, body: body, timestamp: timestamp);
    if (parsed != null) {
      _addAlert(parsed);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER EXTRACTION UTILITIES
  // ─────────────────────────────────────────────────────────────

  String? _extractOtp(String text) {
    // Pattern 1: WhatsApp hyphenated code (e.g. 123-456 or 123 456)
    final pWa = RegExp(r'\b([0-9]{3})[- ]([0-9]{3})\b');
    final mWa = pWa.firstMatch(text);
    if (mWa != null) {
      return '${mWa.group(1)}${mWa.group(2)}';
    }

    // Pattern 2: explicitly preceded by OTP/code keywords
    final p1 = RegExp(
      r'(?:otp|code|passcode|secret\s*code|pin)[\s\w]*(?:is|:|-)?\s*([0-9]{4,8})\b',
      caseSensitive: false,
    );
    final m1 = p1.firstMatch(text);
    if (m1 != null && m1.group(1) != null) {
      final code = m1.group(1)!;
      if (!_isYearOrCommon(code)) return code;
    }

    // Pattern 3: starts with code followed by "is your"
    final p2 = RegExp(r'\b([0-9]{4,8})\s+(?:is\s+your\s+(?:otp|code|verification|passcode))', caseSensitive: false);
    final m2 = p2.firstMatch(text);
    if (m2 != null && m2.group(1) != null) {
      final code = m2.group(1)!;
      if (!_isYearOrCommon(code)) return code;
    }

    // Pattern 4: general 4-6 digit standalone numbers in message that contains "otp"
    final p3 = RegExp(r'\b([0-9]{4,6})\b');
    final matches = p3.allMatches(text);
    for (final m in matches) {
      final code = m.group(1);
      if (code != null && !_isYearOrCommon(code)) {
        return code;
      }
    }

    return null;
  }

  bool _isYearOrCommon(String val) {
    if (val == '2024' || val == '2025' || val == '2026' || val == '2027') return true;
    if (val == '0000' || val == '1234') return true;
    return false;
  }

  double? _extractAmount(String text) {
    final p = RegExp(r'(?:rs\.?|inr|₹)\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)', caseSensitive: false);
    final m = p.firstMatch(text);
    if (m != null && m.group(1) != null) {
      final clean = m.group(1)!.replaceAll(',', '');
      return double.tryParse(clean);
    }
    return null;
  }

  String? _extractRegex(String text, String pattern, {int group = 0}) {
    final reg = RegExp(pattern, caseSensitive: false);
    final match = reg.firstMatch(text);
    if (match != null && match.groupCount >= group) {
      return match.group(group);
    }
    return null;
  }

  String? _extractUrl(String text) {
    final p = RegExp(r'https?://[^\s]+');
    final m = p.firstMatch(text);
    return m?.group(0);
  }

  // ─────────────────────────────────────────────────────────────
  // STORAGE & MUTATION
  // ─────────────────────────────────────────────────────────────

  void _addAlert(SmsAlert alert, {bool notify = true}) {
    final existingIndex = _alerts.indexWhere((a) => a.id == alert.id || (a.body == alert.body && a.timestamp == alert.timestamp));
    if (existingIndex >= 0) return;

    _alerts.insert(0, alert);

    // Limit to 100 alerts in memory
    if (_alerts.length > 100) {
      _alerts.removeRange(100, _alerts.length);
    }

    if (notify) {
      _notifyAndSave();
    }
  }

  void markAlertRead(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      _notifyAndSave();
    }
  }

  void clearAllAlerts() {
    _alerts.clear();
    _notifyAndSave();
  }

  void _notifyAndSave() {
    _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _alertsController.add(List.unmodifiable(_alerts));
    _saveAlertsToPrefs();
  }

  static const _storage = FlutterSecureStorage();

  Future<void> _saveAlertsToPrefs() async {
    try {
      final list = _alerts.map((a) => a.toJson()).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _loadSavedAlerts() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _alerts.clear();
        for (final item in list) {
          if (item is Map) {
            _alerts.add(SmsAlert.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _alertsController.add(List.unmodifiable(_alerts));
      }
    } catch (_) {}
  }

  void dispose() {
    _streamSubscription?.cancel();
    _alertsController.close();
  }
}
