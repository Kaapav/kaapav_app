// lib/screens/orders/orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../config/routes.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/toast.dart';

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
  String _sortBy = 'newest'; // newest | oldest | amount_high | amount_low

  static const _statusTabs = [
    'all', 'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled',
  ];

  static const _statusColors = {
    'pending':    Color(0xFFF59E0B),
    'confirmed':  Color(0xFF3B82F6),
    'processing': Color(0xFF8B5CF6),
    'shipped':    Color(0xFF06B6D4),
    'delivered':  Color(0xFF10B981),
    'cancelled':  Color(0xFFEF4444),
  };

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

  // ── Sort picker ───────────────────────────────────────────────
  void _showSortPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = {
          'newest':      'Newest first',
          'oldest':      'Oldest first',
          'amount_high': 'Amount: High → Low',
          'amount_low':  'Amount: Low → High',
        };
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Sort Orders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ...options.entries.map((e) => ListTile(
                title: Text(e.value),
                trailing: _sortBy == e.key
                    ? Icon(Icons.check_circle_rounded, color: KaapavTheme.gold, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _sortBy = e.key);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Manual order creation ─────────────────────────────────────
  void _createManualOrder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1F1F1F)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreateOrderSheet(
        onCreated: (orderId) {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: orderId);
          KaapavToast.success(context, 'Order $orderId created');
          ref.read(orderProvider.notifier).loadOrders();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pre-count per status for tab badges
    final counts = <String, int>{'all': orderState.orders.length};
    for (final s in _statusTabs.skip(1)) {
      counts[s] = orderState.orders.where((o) => o.status == s).length;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          // Sort button
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: _showSortPicker,
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(orderProvider.notifier).loadOrders(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: KaapavTheme.gold,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: KaapavTheme.gold,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabAlignment: TabAlignment.start,
          tabs: _statusTabs.map((s) {
            final count = counts[s] ?? 0;
            final label = s[0].toUpperCase() + s.substring(1);
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: s == 'pending'
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : (_statusColors[s] ?? KaapavTheme.gold).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: _statusColors[s] ?? KaapavTheme.gold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // ── Search + active filter summary ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search by name, phone, ID...',
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
                if (_sortBy != 'newest') ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _sortBy = 'newest'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: KaapavTheme.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: KaapavTheme.gold.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.filter_alt_rounded,
                          size: 16, color: KaapavTheme.gold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Revenue summary strip (all orders) ──
          if (!orderState.isLoading && orderState.orders.isNotEmpty)
            _RevenueSummary(orders: orderState.orders, isDark: isDark),

          const SizedBox(height: 6),

          // ── Tab content ──
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
        onPressed: _createManualOrder,
        tooltip: 'Create Manual Order',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOrderList(OrderState orderState, String statusFilter) {
    var orders = [...orderState.orders];

    // Status filter
    if (statusFilter != 'all') {
      orders = orders.where((o) => o.status == statusFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      orders = orders.where((o) {
        return o.orderId.toLowerCase().contains(_searchQuery) ||
            (o.customerName ?? '').toLowerCase().contains(_searchQuery) ||
            o.phone.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'oldest':
        orders.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        break;
      case 'amount_high':
        orders.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'amount_low':
        orders.sort((a, b) => a.total.compareTo(b.total));
        break;
      default: // newest
        orders.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
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
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
  order: order,
  // ✅ removed state: orderState
  onTap: () => Navigator.pushNamed(
    context,
    AppRoutes.orderDetail,
    arguments: order.orderId,
  ).then((_) => ref.read(orderProvider.notifier).loadOrders()),
);
        },
      ),
    );
  }
}

// ── Revenue Summary Strip ─────────────────────────────────────
class _RevenueSummary extends StatelessWidget {
  final List orders;
  final bool isDark;
  const _RevenueSummary({required this.orders, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final paid = orders.where((o) => o.paymentStatus == 'paid');
    final revenue = paid.fold<double>(0, (s, o) => s + (o.total as num).toDouble());
    final pending = orders.where((o) => o.status == 'pending').length;
    final today = orders.where((o) {
      final d = o.createdAt ?? '';
      return d.startsWith(DateTime.now().toIso8601String().substring(0, 10));
    }).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          _StatChip(
            label: 'Revenue',
            value: '\u20B9${revenue.toStringAsFixed(0)}',
            color: const Color(0xFF10B981),
          ),
          _Divider(),
          _StatChip(
            label: 'Pending',
            value: '$pending',
            color: const Color(0xFFF59E0B),
          ),
          _Divider(),
          _StatChip(
            label: 'Today',
            value: '$today',
            color: KaapavTheme.gold,
          ),
          _Divider(),
          _StatChip(
            label: 'Total',
            value: '${orders.length}',
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5, height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: const Color(0xFFE5E7EB),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 1),
        Text(label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ],
    ),
  );
}

// ── Create Manual Order Sheet ─────────────────────────────────
class _CreateOrderSheet extends ConsumerStatefulWidget {
  final Function(String orderId) onCreated;
  const _CreateOrderSheet({required this.onCreated});

  @override
  ConsumerState<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<_CreateOrderSheet> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addrCtrl    = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _stateCtrl   = TextEditingController();
  final _pinCtrl     = TextEditingController();
  final _totalCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl,_phoneCtrl,_addrCtrl,_cityCtrl,
                     _stateCtrl,_pinCtrl,_totalCtrl,_notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final total = double.tryParse(_totalCtrl.text.trim());
    if (name.isEmpty || phone.length < 10 || total == null) {
      KaapavToast.error(context, 'Name, phone (10 digits), and total are required');
      return;
    }
    setState(() => _loading = true);
    try {
      final orderId = await ref.read(orderProvider.notifier).createManualOrder(
        name: name,
        phone: '91$phone',
        address: _addrCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state_: _stateCtrl.text.trim(),
        pincode: _pinCtrl.text.trim(),
        total: total,
        notes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      if (orderId != null) {
        widget.onCreated(orderId);
      } else {
        KaapavToast.error(context, 'Failed to create order');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    //final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Create Manual Order',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _Field(ctrl: _nameCtrl,  hint: 'Customer name *',      keyboard: TextInputType.name),
            _Field(ctrl: _phoneCtrl, hint: 'Phone (10 digits) *',  keyboard: TextInputType.phone, maxLen: 10),
            _Field(ctrl: _totalCtrl, hint: 'Total amount *',        keyboard: TextInputType.number),
            _Field(ctrl: _addrCtrl,  hint: 'Address',               maxLines: 2),
            Row(children: [
              Expanded(child: _Field(ctrl: _cityCtrl,  hint: 'City')),
              const SizedBox(width: 10),
              Expanded(child: _Field(ctrl: _pinCtrl,   hint: 'Pincode', keyboard: TextInputType.number, maxLen: 6)),
            ]),
            _Field(ctrl: _stateCtrl, hint: 'State'),
            _Field(ctrl: _notesCtrl, hint: 'Notes (optional)', maxLines: 2),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaapavTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: KaapavTheme.gold.withValues(alpha: 0.5),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Order', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final int? maxLen;
  final int maxLines;
  const _Field({
    required this.ctrl,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.maxLen,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLength: maxLen,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: KaapavTheme.gold),
          ),
        ),
      ),
    );
  }
}