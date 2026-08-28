// lib/providers/sms_alert_provider.dart
// ═══════════════════════════════════════════════════════════════
// SMS & DEVICE ALERTS RIVERPOD PROVIDER
// ═══════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sms_alert_model.dart';
import '../services/sms_alert_service.dart';

class SmsAlertState {
  final List<SmsAlert> alerts;
  final bool hasPermission;
  final bool isLoading;

  const SmsAlertState({
    this.alerts = const [],
    this.hasPermission = false,
    this.isLoading = false,
  });

  SmsAlertState copyWith({
    List<SmsAlert>? alerts,
    bool? hasPermission,
    bool? isLoading,
  }) {
    return SmsAlertState(
      alerts: alerts ?? this.alerts,
      hasPermission: hasPermission ?? this.hasPermission,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get unreadCount => alerts.where((a) => !a.isRead).length;

  SmsAlert? get latestOtp {
    final otps = alerts.where((a) => a.type == 'otp' && !a.isExpired).toList();
    return otps.isNotEmpty ? otps.first : null;
  }
}

final smsAlertProvider =
    StateNotifierProvider<SmsAlertNotifier, SmsAlertState>((ref) {
  return SmsAlertNotifier();
});

class SmsAlertNotifier extends StateNotifier<SmsAlertState> {
  final SmsAlertService _service = SmsAlertService.instance;

  SmsAlertNotifier() : super(const SmsAlertState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _service.init();

    final hasPerm = await _service.checkPermission();
    state = state.copyWith(
      alerts: _service.alerts,
      hasPermission: hasPerm,
      isLoading: false,
    );

    _service.alertsStream.listen((updatedAlerts) {
      state = state.copyWith(alerts: updatedAlerts);
    });
  }

  Future<bool> requestPermission() async {
    final granted = await _service.requestPermission();
    state = state.copyWith(hasPermission: granted, alerts: _service.alerts);
    return granted;
  }

  Future<void> refresh() async {
    await _service.fetchRecentSms();
    state = state.copyWith(alerts: _service.alerts);
  }

  void markAsRead(String id) {
    _service.markAlertRead(id);
    state = state.copyWith(alerts: _service.alerts);
  }

  void clearAll() {
    _service.clearAllAlerts();
    state = state.copyWith(alerts: const []);
  }
}
