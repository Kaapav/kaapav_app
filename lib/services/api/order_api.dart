// lib/services/api/order_api.dart
// ═══════════════════════════════════════════════════════════
// ORDER API
// Matches: worker/handlers/order.js
// ═══════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import '../../config/constants.dart';
import 'api_client.dart';

class OrderApi {
  final ApiClient _client = ApiClient.instance;

  // ── List orders ──────────────────────────────────────────────
  Future<Response> getOrders({
    String? status,
    String? paymentStatus,
    String? phone,
    String? search,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
    CancelToken? cancelToken,
  }) {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != null) params['status'] = status;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (phone != null) params['phone'] = phone;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    return _client.get(
      ApiEndpoints.orders,
      queryParameters: params,
      cacheTTL: const Duration(seconds: 15),
      cancelToken: cancelToken,
    );
  }

  // ── Order stats ──────────────────────────────────────────────
  Future<Response> getOrderStats({String period = 'today'}) {
    return _client.get(
      ApiEndpoints.orderStats,
      queryParameters: {'period': period},
      cacheTTL: const Duration(seconds: 30),
    );
  }

  // ── Single order ─────────────────────────────────────────────
  Future<Response> getOrder(String orderId) {
    return _client.get(
      ApiEndpoints.order(orderId),
      cacheTTL: const Duration(seconds: 10),
    );
  }

  // ── Create order (from chat / WA flow) ───────────────────────
  Future<Response> createOrder(Map<String, dynamic> data) {
    return _client.post(ApiEndpoints.orders, data: data);
  }

  // ── Update order (generic fields) ────────────────────────────
  Future<Response> updateOrder(String orderId, Map<String, dynamic> data) {
    return _client.put(ApiEndpoints.order(orderId), data: data);
  }

  // ── Update status only (manual picker in detail screen) ──────
  // PATCH /api/orders/:orderId/status
  // Body: { status }
  // Auto-sends WhatsApp on confirmed/shipped/delivered/cancelled
  Future<Response> updateOrderStatus(String orderId, String status) {
    return _client.put(
      '/api/orders/$orderId/status',
      data: {'status': status},
    );
  }

  // ── Confirm order ─────────────────────────────────────────────
  Future<Response> confirmOrder(String orderId) {
    return _client.post(ApiEndpoints.orderConfirm(orderId));
  }

  // ── Ship order ────────────────────────────────────────────────
  Future<Response> shipOrder(String orderId, Map<String, dynamic> data) {
    return _client.post(ApiEndpoints.orderShip(orderId), data: data);
  }

  // ── Cancel order ─────────────────────────────────────────────
  Future<Response> cancelOrder(String orderId, {String? reason}) {
    return _client.post(
      ApiEndpoints.orderCancel(orderId),
      data: {'reason': reason ?? 'Cancelled by admin'},
    );
  }

  // ── Generate Razorpay payment link ───────────────────────────
  Future<Response> generatePaymentLink(String orderId) {
    return _client.post(ApiEndpoints.orderPaymentLink(orderId));
  }

  // ── Send WA notification ─────────────────────────────────────
  Future<Response> sendNotification(String orderId, String type) {
    return _client.post(
      '/api/orders/$orderId/send-notification',
      data: {'type': type},
    );
  }

  // ── Create manual order (from Flutter admin app) ─────────────
  // POST /api/orders/manual
  // Body: { name, phone, total, address, city, state, pincode, notes, items[] }
  // Response: { success, orderId }
  Future<Response> createManualOrder({
    required String name,
    required String phone,
    required double total,
    String address = '',
    String city = '',
    String state = '',
    String pincode = '',
    String notes = '',
    List<Map<String, dynamic>> items = const [],
  }) {
    return _client.post(
      '/api/orders/manual',
      data: {
        'name': name,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'total': total,
        'notes': notes,
        'items': items,
        'source': 'manual',
      },
    );
  }
}