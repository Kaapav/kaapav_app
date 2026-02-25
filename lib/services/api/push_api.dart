import 'package:dio/dio.dart';
import 'api_client.dart';

class PushApi {
  final ApiClient _api = ApiClient.instance;

  Future<Response> register(String fcmToken) {
    return _api.post('/api/push/register', data: {
      'fcmToken': fcmToken,
      'platform': 'android',
      'deviceId': 'samsung-s23-ultra',
    });
  }

  Future<Response> unsubscribe() {
    return _api.post('/api/push/unsubscribe');
  }

  Future<Response> test() {
    return _api.post('/api/push/test');
  }
}