import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import '../services/api/dashboard_api.dart';
import '../services/api/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(apiClientProvider));
});

// ═══════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════

class AnalyticsState {
  final bool isLoading;
  final DashboardStats? stats;
  final List<Activity> activities;
  final PendingActions? pending;
  final DashboardOpsData? ops;
  final DateTime? lastSyncAt;
  final String? error;

  const AnalyticsState({
    this.isLoading = false,
    this.stats,
    this.activities = const [],
    this.pending,
    this.ops,
    this.lastSyncAt,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    DashboardStats? stats,
    List<Activity>? activities,
    PendingActions? pending,
    DashboardOpsData? ops,
    DateTime? lastSyncAt,
    String? error,
    bool clearError = false,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      activities: activities ?? this.activities,
      pending: pending ?? this.pending,
      ops: ops ?? this.ops,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final DashboardApi _api;
  Timer? _syncTimer;
  bool _isFetching = false;

  AnalyticsNotifier(this._api) : super(const AnalyticsState());

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    if (_isFetching) return;
    _isFetching = true;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final results = await Future.wait([
        _api.getStats(),
        _api.getActivities(),
        _api.getPending(),
        _api.getOps(),
      ]);

      state = state.copyWith(
        isLoading: false,
        stats: results[0] as DashboardStats,
        activities: results[1] as List<Activity>,
        pending: results[2] as PendingActions,
        ops: results[3] as DashboardOpsData,
        lastSyncAt: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refreshStats() async {
    try {
      final stats = await _api.getStats();
      state = state.copyWith(
        stats: stats,
        lastSyncAt: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> refreshPending() async {
    try {
      final pending = await _api.getPending();
      state = state.copyWith(
        pending: pending,
        lastSyncAt: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> refreshActivities() async {
    try {
      final activities = await _api.getActivities();
      state = state.copyWith(
        activities: activities,
        lastSyncAt: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> refreshOps() async {
    try {
      final ops = await _api.getOps();
      state = state.copyWith(
        ops: ops,
        lastSyncAt: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> refreshLight() async {
    if (_isFetching) return;
    try {
      final results = await Future.wait([
        _api.getStats(),
        _api.getPending(),
        _api.getOps(),
      ]);

      state = state.copyWith(
        stats: results[0] as DashboardStats,
        pending: results[1] as PendingActions,
        ops: results[2] as DashboardOpsData,
        lastSyncAt: DateTime.now(),
      );
    } catch (_) {}
  }

  void startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshLight();
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref.watch(dashboardApiProvider));
});