// lib/services/api/dashboard_api.dart

import '../../models/analytics_model.dart';
import 'api_client.dart';

class DashboardApi {
  final ApiClient _client;
  DashboardApi(this._client);

  // ── /api/stats ─────────────────────────────────────────────────
  // Response: { success: true, stats: { totalChats, unreadMessages,
  //   totalOrders, pendingOrders, totalCustomers, totalProducts,
  //   totalRevenue } }
  Future<DashboardStats> getStats() async {
    final response = await _client.get('/api/stats');

    // ApiClient returns Response<dynamic> — extract .data as Map
    final Map<String, dynamic> body = _toMap(response);
    final Map<String, dynamic> stats =
        (body['stats'] as Map<String, dynamic>?) ?? {};

    return DashboardStats.fromJson(stats);
  }

  // ── /api/analytics/activities ──────────────────────────────────
  // Response: { success: true,
  //   activities: [ { phone, text, direction, timestamp } ] }
  Future<List<Activity>> getActivities() async {
    final response = await _client.get('/api/analytics/activities');

    final Map<String, dynamic> body = _toMap(response);
    final List<dynamic> raw =
        (body['activities'] as List<dynamic>?) ?? [];

    return raw
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── /api/analytics/pending ─────────────────────────────────────
  // Response: { success: true,
  //   pending: [ ...order rows with status/payment_status... ] }
  // We compute PendingActions counts from that raw orders list.
  Future<PendingActions> getPending() async {
    final response = await _client.get('/api/analytics/pending');

    final Map<String, dynamic> body = _toMap(response);
    final List<dynamic> raw =
        (body['pending'] as List<dynamic>?) ?? [];

    return PendingActions.fromOrdersList(raw);
  }

  // ── Helper: safely convert ApiClient response to Map ───────────
  // Handles the case where ApiClient returns Response<dynamic>,
  // Dio Response, or already a Map.
  Map<String, dynamic> _toMap(dynamic response) {
    // If ApiClient already returns a decoded Map
    if (response is Map<String, dynamic>) {
      return response;
    }
    // If it's a Dio/http Response object with a .data property
    try {
      final data = (response as dynamic).data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return {};
  }
}