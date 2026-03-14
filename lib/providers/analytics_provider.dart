// lib/providers/analytics_provider.dart

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

// ── State ─────────────────────────────────────────────────────────────────────

class AnalyticsState {
  final bool isLoading;
  final DashboardStats? stats;
  final List<Activity> activities;
  final PendingActions? pending;
  final String? error;

  const AnalyticsState({
    this.isLoading  = false,
    this.stats,
    this.activities = const [],
    this.pending,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    DashboardStats? stats,
    List<Activity>? activities,
    PendingActions? pending,
    String? error,
  }) {
    return AnalyticsState(
      isLoading:  isLoading  ?? this.isLoading,
      stats:      stats      ?? this.stats,
      activities: activities ?? this.activities,
      pending:    pending    ?? this.pending,
      error:      error      ?? this.error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final DashboardApi _api;
  Timer? _syncTimer;

  AnalyticsNotifier(this._api) : super(const AnalyticsState());

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _api.getStats(),
        _api.getActivities(),
        _api.getPending(),
      ]);
      state = state.copyWith(
        isLoading:  false,
        stats:      results[0] as DashboardStats,
        activities: results[1] as List<Activity>,
        pending:    results[2] as PendingActions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     e.toString(),
      );
    }
  }

  Future<void> refreshStats() async {
    try {
      final stats = await _api.getStats();
      state = state.copyWith(stats: stats);
    } catch (_) {}
  }

  Future<void> refreshPending() async {
    try {
      final pending = await _api.getPending();
      state = state.copyWith(pending: pending);
    } catch (_) {}
  }

  Future<void> refreshActivities() async {
    try {
      final activities = await _api.getActivities();
      state = state.copyWith(activities: activities);
    } catch (_) {}
  }

  /// Called by home_screen.dart — starts periodic background sync
  void startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshStats();
      refreshPending();
    });
  }

  /// Called by home_screen.dart — stops periodic background sync
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref.watch(dashboardApiProvider));
});