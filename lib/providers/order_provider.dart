// lib/providers/order_provider.dart
// ═══════════════════════════════════════════════════════════
// ORDER STATE MANAGEMENT
// ═══════════════════════════════════════════════════════════

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
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
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

  // ═══════════════════════════════════════════════════════════
  // LOAD ORDERS
  // ═══════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════
  // LOAD MORE
  // ═══════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════
  // LOAD STATS
  // ═══════════════════════════════════════════════════════════

  Future<void> loadStats({String period = 'today'}) async {
    try {
      final response = await _api.getOrderStats(period: period);
      state = state.copyWith(stats: response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Load order stats error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════
  // ORDER ACTIONS
  // ═══════════════════════════════════════════════════════════

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

  Future<bool> sendNotification(String orderId, String type) async {
    try {
      await _api.sendNotification(orderId, type);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

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