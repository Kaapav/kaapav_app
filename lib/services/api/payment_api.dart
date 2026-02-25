// ───────────────────────────────────────────────────────────────────
// lib/services/api/payment_api.dart
// ───────────────────────────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'api_client.dart';

class PaymentApi {
  final ApiClient _api = ApiClient.instance;

  Future<Response> createLink(String orderId, double amount) {
    return _api.post('/api/payments/create-link', data: {
      'orderId': orderId,
      'amount': amount,
    });
  }

  Future<Response> getStatus(String paymentId) {
    return _api.get('/api/payments/$paymentId');
  }

  Future<Response> refund(String paymentId, double amount) {
    return _api.post('/api/payments/$paymentId/refund', data: {
      'amount': amount,
    });
  }
}