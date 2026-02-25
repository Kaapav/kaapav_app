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

  // ═══════════════════════════════════════════════════════════
  // LIST ORDERS
  // GET /api/orders?status=&payment_status=&phone=&search=&start_date=&end_date=&limit=&offset=
  // Response: { orders[], total, limit, offset }
  // ═══════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════
  // ORDER STATS
  // GET /api/orders/stats?period=today|week|month|year
  // Response: { stats: { totalOrders, totalRevenue, avgOrderValue, byStatus{}, paid, unpaid }, daily[] }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getOrderStats({String period = 'today'}) {
    return _client.get(
      ApiEndpoints.orderStats,
      queryParameters: {'period': period},
      cacheTTL: const Duration(seconds: 30),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GET SINGLE ORDER (with payments)
  // GET /api/orders/:orderId
  // Response: { order: {}, payments[] }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getOrder(String orderId) {
    return _client.get(
      ApiEndpoints.order(orderId),
      cacheTTL: const Duration(seconds: 10),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CREATE ORDER
  // POST /api/orders
  // Body: { phone, items[{sku, quantity}], shippingAddress{}, paymentMethod, discountCode, customerNotes }
  // Response: { success, orderId, total, paymentLink? }
  // ═══════════════════════════════════════════════════════════

  Future<Response> createOrder(Map<String, dynamic> data) {
    return _client.post(ApiEndpoints.orders, data: data);
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE ORDER
  // PUT /api/orders/:orderId
  // Body: { status, payment_status, tracking_id, tracking_url, courier, internal_notes, shipping_* }
  // ═══════════════════════════════════════════════════════════

  Future<Response> updateOrder(String orderId, Map<String, dynamic> data) {
    return _client.put(ApiEndpoints.order(orderId), data: data);
  }

  // ═══════════════════════════════════════════════════════════
  // CONFIRM ORDER
  // POST /api/orders/:orderId/confirm
  // Sends WhatsApp confirmation + updates customer stats
  // ═══════════════════════════════════════════════════════════

  Future<Response> confirmOrder(String orderId) {
    return _client.post(ApiEndpoints.orderConfirm(orderId));
  }

  // ═══════════════════════════════════════════════════════════
  // SHIP ORDER
  // POST /api/orders/:orderId/ship
  // Body: { courier, trackingId, trackingUrl, useShiprocket? }
  // Sends WhatsApp shipping notification
  // ═══════════════════════════════════════════════════════════

  Future<Response> shipOrder(String orderId, Map<String, dynamic> data) {
    return _client.post(ApiEndpoints.orderShip(orderId), data: data);
  }

  // ═══════════════════════════════════════════════════════════
  // CANCEL ORDER
  // POST /api/orders/:orderId/cancel
  // Body: { reason }
  // Restores inventory + notifies customer
  // ═══════════════════════════════════════════════════════════

  Future<Response> cancelOrder(String orderId, {String? reason}) {
    return _client.post(
      ApiEndpoints.orderCancel(orderId),
      data: {'reason': reason ?? 'Cancelled by admin'},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GENERATE PAYMENT LINK (Razorpay)
  // POST /api/orders/:orderId/payment-link
  // Sends payment link to customer via WhatsApp
  // Response: { success, paymentLink }
  // ═══════════════════════════════════════════════════════════

  Future<Response> generatePaymentLink(String orderId) {
    return _client.post(ApiEndpoints.orderPaymentLink(orderId));
  }

  // ═══════════════════════════════════════════════════════════
  // SEND ORDER NOTIFICATION
  // POST /api/orders/:orderId/send-notification
  // Body: { type: "confirmation"|"shipped"|"delivered"|"payment_reminder" }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendNotification(String orderId, String type) {
    return _client.post(
      '/api/orders/$orderId/send-notification',
      data: {'type': type},
    );
  }
}