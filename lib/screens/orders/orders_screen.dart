// lib/screens/orders/orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  final List<String> _statusTabs = [
    'all',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    Future.microtask(() => ref.read(orderProvider.notifier).loadOrders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: KaapavTheme.gold,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: KaapavTheme.gold,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _statusTabs
              .map((s) => Tab(text: s[0].toUpperCase() + s.substring(1)))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search orders...',
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child: orderState.isLoading
                ? const ShimmerLoading(type: ShimmerType.orderList, itemCount: 6)
                : TabBarView(
                    controller: _tabController,
                    children: _statusTabs.map((status) {
                      return _buildOrderList(orderState, status);
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KaapavTheme.gold,
        onPressed: () {
          // TODO: Create manual order
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOrderList(OrderState orderState, String statusFilter) {
    var orders = orderState.orders;

    if (statusFilter != 'all') {
      orders = orders.where((o) => o.status == statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      orders = orders.where((o) {
        final orderId = o.orderId.toLowerCase();
        final name = (o.customerName ?? '').toLowerCase();
        final phone = o.phone.toLowerCase();
        return orderId.contains(_searchQuery) ||
            name.contains(_searchQuery) ||
            phone.contains(_searchQuery);
      }).toList();
    }

    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders',
        subtitle: statusFilter == 'all'
            ? 'Orders will appear here'
            : 'No $statusFilter orders',
      );
    }

    return RefreshIndicator(
      color: KaapavTheme.gold,
      onRefresh: () => ref.read(orderProvider.notifier).loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.orderDetail,
                arguments: order.orderId,
              );
            },
          );
        },
      ),
    );
  }
}