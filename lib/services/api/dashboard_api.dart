// lib/services/api/dashboard_api.dart

import '../../models/analytics_model.dart';
import 'api_client.dart';

class DashboardApi {
  final ApiClient apiClient;

  DashboardApi(this.apiClient);

  Future<DashboardStats> getStats() async {
    final response = await apiClient.get('/api/stats');
    return DashboardStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Activity>> getActivities({int limit = 10}) async {
    final response = await apiClient.get('/api/analytics/activities?limit=$limit');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Activity.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<PendingActions> getPending() async {
    final response = await apiClient.get('/api/analytics/pending');
    return PendingActions.fromJson(response.data as Map<String, dynamic>);
  }
}