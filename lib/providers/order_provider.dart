// lib/providers/order_provider.dart
// ═══════════════════════════════════════════════════════════
// ORDER STATE MANAGEMENT
// ═══════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/api/order_api.dart';
import '../services/api/api_client.dart';
import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════

class OrderState {
  final List<Order> orders;
  final int totalOrders;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? statusFilter;
  final String? searchQuery;
  final Map<String, dynamic>? stats;

  const OrderState({
    this.orders = const [],
    this.totalOrders = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.statusFilter,
    this.searchQuery,
    this.stats,
  });

  int get pendingCount => orders.where((o) => o.status == 'pending').length;

  OrderState copyWith({
    List<Order>? orders,
    int? totalOrders,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? statusFilter,
    String? searchQuery,
    Map<String, dynamic>? stats,
    bool clearError = false,
    bool clearStatusFilter = false,
    bool clearSearchQuery = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      totalOrders: totalOrders ?? this.totalOrders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      stats: stats ?? this.stats,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════

final orderProvider =
    StateNotifierProvider<OrderNotifier, OrderState>((ref) => OrderNotifier());

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderApi _api = OrderApi();

  OrderNotifier() : super(const OrderState());

  // ── Load orders ─────────────────────────────────────────────
  Future<void> loadOrders({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.getOrders(
        status: state.statusFilter,
        search: state.searchQuery,
      );
      final data = response.data as Map<String, dynamic>;
      final orderList = (data['orders'] as List? ?? [])
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        orders: orderList,
        totalOrders: data['total'] ?? orderList.length,
        isLoading: false,
      );
    } on ApiError catch (e) {
      state = state.copyWith(isLoading: false, error: e.displayMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load orders');
    }
  }

  // ── Load more ────────────────────────────────────────────────
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.orders.length >= state.totalOrders) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final response = await _api.getOrders(
        status: state.statusFilter,
        search: state.searchQuery,
        offset: state.orders.length,
      );
      final data = response.data as Map<String, dynamic>;
      final newOrders = (data['orders'] as List? ?? [])
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        orders: [...state.orders, ...newOrders],
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // ── Load stats ───────────────────────────────────────────────
  Future<void> loadStats({String period = 'today'}) async {
    try {
      final response = await _api.getOrderStats(period: period);
      state = state.copyWith(stats: response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Load order stats error: $e');
    }
  }

  // ── Filters ──────────────────────────────────────────────────
  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await loadOrders();
  }

  Future<void> setSearch(String query) async {
    state = state.copyWith(
      searchQuery: query.isEmpty ? null : query,
      clearSearchQuery: query.isEmpty,
    );
    await loadOrders();
  }

  // ── Confirm ──────────────────────────────────────────────────
  Future<bool> confirmOrder(
    String orderId, {
    required String paymentId,
    String? phone,
  }) async {
    try {
      await _api.confirmOrder(
        orderId,
        paymentId: paymentId,
        phone: phone,
      );

      _updateOrderLocal(
        orderId,
        (o) => o.copyWith(
          status: 'confirmed',
          paymentStatus: 'paid',
          paymentId: paymentId,
        ),
      );
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    }
  }

  // ── Ship ─────────────────────────────────────────────────────
  Future<bool> shipOrder(String orderId, Map<String, dynamic> data) async {
    try {
      await _api.shipOrder(orderId, data);

      _updateOrderLocal(
        orderId,
        (o) => o.copyWith(
          status: 'shipped',
          awbNumber: data['awb']?.toString(),
          courier: data['courier']?.toString(),
          trackingUrl: data['awb'] != null
              ? 'https://www.shiprocket.in/shipment-tracking/?id=${data['awb']}'
              : o.trackingUrl,
        ),
      );
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    }
  }
 
    // ── Update AWB / courier ─────────────────────────────────────
  Future<bool> updateAwb(
    String orderId, {
    required String awb,
    String? courier,
  }) async {
    try {
      final response = await _api.updateAwb(
        orderId,
        awb: awb,
        courier: courier,
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        _updateOrderLocal(
          orderId,
          (o) => o.copyWith(
            status: 'shipped',
            awbNumber: awb,
            courier: courier ?? 'Shiprocket',
            trackingUrl: 'https://www.shiprocket.in/shipment-tracking/?id=$awb',
          ),
        );
        return true;
      }
      return false;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── Get order events ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getOrderEvents(String orderId) async {
    try {
      final response = await _api.getOrderEvents(orderId);
      final data = response.data as Map<String, dynamic>;
      final events = (data['events'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return events;
    } catch (_) {
      return [];
    }
  }

  // ── Send Invoice ─────────────────────────────────────────
  Future<bool> sendInvoice(String orderId) async {
    try {
      final response = await _api.sendInvoice(orderId);
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      debugPrint('Send invoice error: $e');
      return false;
    }
  }

  // ── Download Invoice PDF ─────────────────────────────────
  Future<bool> downloadInvoicePdf(String orderId, String savePath) async {
    try {
      final response = await ApiClient.instance.dio.get<List<int>>(
        '/api/orders/$orderId/invoice-pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return false;

      final file = File(savePath);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    } catch (e) {
      debugPrint('Download invoice error: $e');
      return false;
    }
  }

    // ── Cancel ───────────────────────────────────────────────────
    Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final response = await _api.cancelOrder(orderId, reason: reason);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        _updateOrderLocal(
          orderId,
          (o) => o.copyWith(
            status: 'cancelled',
            cancellationReason: reason ?? 'Cancelled by admin',
          ),
        );
        return true;
      }
      return false;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Update status (manual, any → any) ───────────────────────
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _updateOrderLocal(orderId, (o) => o.copyWith(status: newStatus));

      final response = await _api.updateOrderStatus(orderId, newStatus);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) return true;

      await loadOrders(silent: true);
      return false;
    } on ApiError catch (e) {
      await loadOrders(silent: true);
      state = state.copyWith(error: e.displayMessage);
      return false;
    } catch (e) {
      await loadOrders(silent: true);
      return false;
    }
  }

    // ── Update customer/shipping details ─────────────────────────
  Future<bool> updateOrderDetails(
    String orderId, {
    required String customerName,
    required String phone,
    required String shippingName,
    required String shippingAddress,
    required String shippingCity,
    required String shippingState,
    required String shippingPincode,
  }) async {
    try {
      final response = await _api.updateOrderDetails(
        orderId,
        customerName: customerName,
        phone: phone,
        shippingName: shippingName,
        shippingAddress: shippingAddress,
        shippingCity: shippingCity,
        shippingState: shippingState,
        shippingPincode: shippingPincode,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _updateOrderLocal(
          orderId,
          (o) => o.copyWith(
            customerName: customerName,
            phone: phone,
            shippingName: shippingName,
            shippingAddress: shippingAddress,
            shippingCity: shippingCity,
            shippingState: shippingState,
            shippingPincode: shippingPincode,
          ),
        );
        return true;
      }
      return false;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    } catch (_) {
      return false;
    }
  }

     // ── Update payment info ──────────────────────────────────────
  Future<bool> updateOrderPayment(
    String orderId, {
    required String paymentStatus,
    String paymentId = '',
  }) async {
    try {
      final response = await _api.updateOrderPayment(
        orderId,
        paymentStatus: paymentStatus,
        paymentId: paymentId,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _updateOrderLocal(
          orderId,
          (o) => o.copyWith(
            paymentStatus: paymentStatus,
            paymentId: paymentId.isNotEmpty ? paymentId : o.paymentId,
            status: data['status']?.toString() ?? o.status,
          ),
        );
        return true;
      }
      return false;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Update internal notes ────────────────────────────────────
    Future<bool> updateOrderNotes(String orderId, String notes) async {
    try {
      final response = await _api.updateOrderNotes(orderId, notes);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        _updateOrderLocal(
          orderId,
          (o) => o.copyWith(internalNotes: notes),
        );
        return true;
      }
      return false;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Generate payment link ────────────────────────────────────
    Future<String?> generatePaymentLink(String orderId) async {
    try {
      final response = await _api.generatePaymentLink(orderId);
      debugPrint('PAYMENT LINK RESPONSE RAW: ${response.data}');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['paymentLink'] as String?;
      }

      debugPrint('PAYMENT LINK FAILED RESPONSE BODY: $data');
      state = state.copyWith(
        error: data['error']?.toString() ??
            data['message']?.toString() ??
            'Failed to generate payment link',
      );
      return null;
    } on ApiError catch (e) {
      debugPrint('PAYMENT LINK API ERROR: ${e.displayMessage}');
      state = state.copyWith(error: e.displayMessage);
      return null;
    } catch (e) {
      debugPrint('PAYMENT LINK ERROR: $e');
      state = state.copyWith(error: 'Failed to generate payment link');
      return null;
    }
  }

  // ── Book Shiprocket ──────────────────────────────────────────
  Future<Map<String, dynamic>> bookShiprocket(String orderId) async {
    try {
      final response = await _api.bookShiprocket(orderId);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        _updateOrderLocal(
          orderId,
          (o) => o.copyWith(status: 'processing'),
        );

        return {
          'success': true,
          'shiprocketOrderId': data['shiprocketOrderId'] ?? '',
          'message': data['message'] ?? 'Booked successfully',
        };
      }

      await loadOrders(silent: true);
      return {
        'success': false,
        'message': data['error'] ?? data['message'] ?? 'Booking failed',
      };
    } on ApiError catch (e) {
      await loadOrders(silent: true);
      state = state.copyWith(error: e.displayMessage);
      return {'success': false, 'message': e.displayMessage};
    } catch (e) {
      await loadOrders(silent: true);
      return {'success': false, 'message': 'Failed: $e'};
    }
  }

  // ── Send notification ────────────────────────────────────────
  Future<bool> sendNotification(String orderId, String type) async {
    try {
      await _api.sendNotification(orderId, type);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Create manual order ──────────────────────────────────────
  Future<String?> createManualOrder({
    required String name,
    required String phone,
    required double total,
    String address = '',
    String city = '',
    String state_ = '',
    String pincode = '',
    String notes = '',
    List<Map<String, dynamic>> items = const [],
  }) async {
    try {
      final response = await _api.createManualOrder(
        name: name,
        phone: phone,
        total: total,
        address: address,
        city: city,
        state: state_,
        pincode: pincode,
        notes: notes,
        items: items,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final orderId = data['orderId'] as String?;
        await loadOrders(silent: true);
        return orderId;
      }
      return null;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return null;
    } catch (e) {
      debugPrint('createManualOrder error: $e');
      return null;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  void _updateOrderLocal(String orderId, Order Function(Order) updater) {
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.orderId == orderId) return updater(o);
        return o;
      }).toList(),
    );
  }

    // ── Fetch single order by ID ─────────────────────────────────
  Future<Order?> fetchOrderById(String orderId) async {
    try {
      final existing = getOrderById(orderId);
      if (existing != null) return existing;

      final response = await _api.getOrder(orderId);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['order'] != null) {
        final fetched = Order.fromJson(data['order'] as Map<String, dynamic>);

        final alreadyExists = state.orders.any((o) => o.orderId == orderId);
        if (!alreadyExists) {
          state = state.copyWith(
            orders: [...state.orders, fetched],
          );
        } else {
          _updateOrderLocal(orderId, (_) => fetched);
        }

        return fetched;
      }

      return null;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to load order');
      return null;
    }
  }

  Order? getOrderById(String orderId) {
    try {
      return state.orders.firstWhere((o) => o.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}