// lib/services/api/order_api.dart
// ═══════════════════════════════════════════════════════════
// ORDER API
// Matches current worker routes
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

  // ── Create order (generic) ───────────────────────────────────
  Future<Response> createOrder(Map<String, dynamic> data) {
    return _client.post(ApiEndpoints.orders, data: data);
  }

  // ── Update order (generic fields) ────────────────────────────
  Future<Response> updateOrder(String orderId, Map<String, dynamic> data) {
    return _client.put(ApiEndpoints.order(orderId), data: data);
  }

  // ── Update status only ───────────────────────────────────────
  // Worker route:
  // PUT /api/orders/:id/status
  // Body: { status }
  Future<Response> updateOrderStatus(String orderId, String status) {
    return _client.put(
      '/api/orders/$orderId/status',
      data: {'status': status},
    );
  }

    // ── Update customer/shipping details ─────────────────────────
  Future<Response> updateOrderDetails(
    String orderId, {
    required String customerName,
    required String phone,
    required String shippingName,
    required String shippingAddress,
    required String shippingCity,
    required String shippingState,
    required String shippingPincode,
  }) {
    return _client.patch(
      '/api/orders/$orderId/details',
      data: {
        'customerName': customerName,
        'phone': phone,
        'shippingName': shippingName,
        'shippingAddress': shippingAddress,
        'shippingCity': shippingCity,
        'shippingState': shippingState,
        'shippingPincode': shippingPincode,
      },
    );
  }

     // ── Update payment info ──────────────────────────────────────
  Future<Response> updateOrderPayment(
    String orderId, {
    required String paymentStatus,
    String paymentId = '',
  }) {
    return _client.patch(
      '/api/orders/$orderId/payment',
      data: {
        'paymentStatus': paymentStatus,
        'paymentId': paymentId,
      },
    );
  }

  // ── Update internal notes ────────────────────────────────────
  // Worker route:
  // PATCH /api/orders/:id/notes
  // Body: { notes }
  Future<Response> updateOrderNotes(String orderId, String notes) {
    return _client.patch(
      '/api/orders/$orderId/notes',
      data: {'notes': notes},
    );
  }

  // ── Confirm order / payment manually ─────────────────────────
  // Worker route:
  // POST /api/orders/confirm
  // Body: { orderId, paymentId, phone }
  Future<Response> confirmOrder(
    String orderId, {
    required String paymentId,
    String? phone,
  }) {
    return _client.post(
      '/api/orders/confirm',
      data: {
        'orderId': orderId,
        'paymentId': paymentId,
        if (phone != null) 'phone': phone,
      },
    );
  }

  // ── Ship order via AWB update ────────────────────────────────
  // Worker route:
  // PUT /api/orders/:id/awb
  // Body: { awb, courier }
  Future<Response> shipOrder(String orderId, Map<String, dynamic> data) {
    return _client.put(
      '/api/orders/$orderId/awb',
      data: data,
    );
  }

  // ── Book Shiprocket ──────────────────────────────────────────
  // Worker route:
  // POST /api/orders/:id/ship
  Future<Response> bookShiprocket(String orderId) {
    return _client.post(
      '/api/orders/$orderId/ship',
      data: {},
    );
  }

    // ── Update AWB / courier ─────────────────────────────────────
  Future<Response> updateAwb(
    String orderId, {
    required String awb,
    String? courier,
  }) {
    return _client.put(
      '/api/orders/$orderId/awb',
      data: {
        'awb': awb,
        'courier': courier ?? 'Shiprocket',
      },
    );
  }

  // ── Get order events ─────────────────────────────────────────
  Future<Response> getOrderEvents(String orderId) {
    return _client.get('/api/orders/$orderId/events');
  }

    // ── Cancel order with reason ─────────────────────────────────
  Future<Response> cancelOrder(String orderId, {String? reason}) {
    return _client.patch(
      '/api/orders/$orderId/cancel',
      data: {'reason': reason ?? 'Cancelled by admin'},
    );
  }

  // ── Generate Razorpay payment link ───────────────────────────
  // Worker route:
  // POST /api/orders/:id/payment-link
  Future<Response> generatePaymentLink(String orderId) {
    return _client.post('/api/orders/$orderId/payment-link');
  }

  // ── Send WhatsApp notification ───────────────────────────────
  // Worker route:
  // POST /api/orders/:id/send-notification
  // Type supported: confirmed / shipped / delivered
  Future<Response> sendNotification(String orderId, String type) {
    return _client.post(
      '/api/orders/$orderId/send-notification',
      data: {'type': type == 'confirmation' ? 'confirmed' : type},
    );
  }

  // ── Create manual order ──────────────────────────────────────
  // Worker route:
  // POST /api/orders/manual
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