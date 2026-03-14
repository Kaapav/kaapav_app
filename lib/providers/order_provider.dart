// lib/providers/order_provider.dart
// ═══════════════════════════════════════════════════════════
// ORDER STATE MANAGEMENT
// ═══════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
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
  Future<bool> confirmOrder(String orderId) async {
    try {
      await _api.confirmOrder(orderId);
      _updateOrderLocal(orderId, (o) => o.copyWith(status: 'confirmed'));
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
      _updateOrderLocal(orderId, (o) => o.copyWith(status: 'shipped'));
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    }
  }

  // ── Cancel ───────────────────────────────────────────────────
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _api.cancelOrder(orderId, reason: reason);
      _updateOrderLocal(orderId, (o) => o.copyWith(status: 'cancelled'));
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return false;
    }
  }

  // ── Update status (manual, any → any) ───────────────────────
  // Called by the status picker in OrderDetailScreen
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Optimistic update first — feels instant
      _updateOrderLocal(orderId, (o) => o.copyWith(status: newStatus));

      final response = await _api.updateOrderStatus(orderId, newStatus);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) return true;

      // Rollback on failure — reload from server
      await loadOrders(silent: true);
      return false;
    } on ApiError catch (e) {
      await loadOrders(silent: true); // rollback
      state = state.copyWith(error: e.displayMessage);
      return false;
    } catch (e) {
      await loadOrders(silent: true);
      return false;
    }
  }

  // ── Generate payment link ────────────────────────────────────
  Future<String?> generatePaymentLink(String orderId) async {
    try {
      final response = await _api.generatePaymentLink(orderId);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['paymentLink'] as String?;
      }
      return null;
    } on ApiError catch (e) {
      state = state.copyWith(error: e.displayMessage);
      return null;
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

  // ── Create manual order (from Flutter app) ───────────────────
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
        await loadOrders(silent: true); // refresh list quietly
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

  Order? getOrderById(String orderId) {
    try {
      return state.orders.firstWhere((o) => o.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}