// ───────────────────────────────────────────────────────────────────
// lib/services/api/settings_api.dart
// ───────────────────────────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'api_client.dart';

class SettingsApi {
  final ApiClient _api = ApiClient.instance;

  Future<Response> get() {
    return _api.get('/api/settings');
  }

  Future<Response> update(Map<String, dynamic> data) {
    return _api.put('/api/settings', data: data);
  }

  Future<Response> testWhatsApp(String phone) {
    return _api.post('/api/settings/test-whatsapp', data: {
      'phone': phone,
    });
  }
}