// ───────────────────────────────────────────────────────────────────
// lib/services/api/shipping_api.dart
// ───────────────────────────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'api_client.dart';

class ShippingApi {
  final ApiClient _api = ApiClient.instance;

  Future<Response> checkServiceability(String pincode) {
    return _api.get('/api/shipping/serviceability/$pincode');
  }

  Future<Response> createShipment(String orderId, Map<String, dynamic> data) {
    return _api.post('/api/shipping/create', data: {
      'orderId': orderId,
      ...data,
    });
  }

  Future<Response> getTracking(String awbNumber) {
    return _api.get('/api/shipping/track/$awbNumber');
  }

  Future<Response> generateLabel(String shipmentId) {
    return _api.get('/api/shipping/label/$shipmentId');
  }

  Future<Response> cancelShipment(String shipmentId) {
    return _api.post('/api/shipping/cancel/$shipmentId');
  }
}
