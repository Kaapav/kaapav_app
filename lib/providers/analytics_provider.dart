// lib/providers/analytics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import '../services/api/dashboard_api.dart';
import '../services/api/api_client.dart';

// Provider for ApiClient using singleton instance
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

// Provider for DashboardApi
final dashboardApiProvider = Provider<DashboardApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardApi(apiClient);
});

// Analytics State
class AnalyticsState {
  final bool isLoading;
  final PendingActions? pending;
  final DashboardStats? stats;
  final List<Activity> activities;
  final String? error;

  AnalyticsState({
    this.isLoading = false,
    this.pending,
    this.stats,
    this.activities = const [],
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    PendingActions? pending,
    DashboardStats? stats,
    List<Activity>? activities,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      pending: pending ?? this.pending,
      stats: stats ?? this.stats,
      activities: activities ?? this.activities,
      error: error ?? this.error,
    );
  }
}

// Analytics Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final DashboardApi _dashboardApi;

  AnalyticsNotifier(this._dashboardApi) : super(AnalyticsState());

  // Load complete dashboard data
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final stats = await _dashboardApi.getStats();
      final activities = await _dashboardApi.getActivities();
      final pending = await _dashboardApi.getPending();
      
      state = state.copyWith(
        isLoading: false,
        stats: stats,
        activities: activities,
        pending: pending,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refresh stats only
  Future<void> refreshStats() async {
    try {
      final stats = await _dashboardApi.getStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Silent fail for refresh
    }
  }

  // Refresh pending actions
  Future<void> refreshPending() async {
    try {
      final pending = await _dashboardApi.getPending();
      state = state.copyWith(pending: pending);
    } catch (e) {
      // Silent fail for refresh
    }
  }

  // Refresh activities
  Future<void> refreshActivities() async {
    try {
      final activities = await _dashboardApi.getActivities();
      state = state.copyWith(activities: activities);
    } catch (e) {
      // Silent fail for refresh
    }
  }

  // Start periodic sync
  void startSync() {
    // TODO: Implement periodic refresh if needed
  }

  // Stop periodic sync
  void stopSync() {
    // TODO: Implement stopping periodic refresh if needed
  }
}

// Analytics Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final dashboardApi = ref.watch(dashboardApiProvider);
  return AnalyticsNotifier(dashboardApi);
});