// lib/services/api/broadcast_api.dart

import 'package:dio/dio.dart';
import 'api_client.dart';

class BroadcastApi {
  final ApiClient _api = ApiClient.instance;

  Future<Response> getBroadcasts() {
    return _api.get('/api/broadcasts');
  }

  Future<Response> getBroadcast(String id) {
    return _api.get('/api/broadcasts/$id');
  }

  Future<Response> createBroadcast(Map<String, dynamic> data) {
    return _api.post('/api/broadcasts', data: data);
  }

  Future<Response> startBroadcast(String id) {
    return _api.post('/api/broadcasts/$id/start');
        
  }

  Future<Response> cancelBroadcast(String id) {
    return _api.post('/api/broadcasts/$id/cancel');
  }

  Future<Response> getRecipients(String id) {
    return _api.get('/api/broadcasts/$id/recipients');
  }
}