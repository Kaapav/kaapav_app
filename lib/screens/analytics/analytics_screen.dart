// lib/screens/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../providers/analytics_provider.dart';
import '../../models/analytics_model.dart';       
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    Future.microtask(() async {
      await ref.read(analyticsProvider.notifier).loadDashboard();
      await ref.read(orderProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 100000) return '\u20B9${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '\u20B9${(v / 1000).toStringAsFixed(1)}K';
    return '\u20B9${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final orders = ref.watch(orderProvider).orders;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5);
    final card = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE5E7EB);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    const sub = Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: text,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await ref.read(analyticsProvider.notifier).loadDashboard();
              await ref.read(orderProvider.notifier).loadOrders();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: KaapavTheme.gold,
          unselectedLabelColor: sub,
          indicatorColor: KaapavTheme.gold,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: state.isLoading && state.stats == null
          ? const Center(
              child:
                  CircularProgressIndicator(color: KaapavTheme.gold))
          : RefreshIndicator(
              color: KaapavTheme.gold,
              onRefresh: () async {
                await ref.read(analyticsProvider.notifier).loadDashboard();
                await ref.read(orderProvider.notifier).loadOrders();
              },
              child: TabBarView(
                controller: _tab,
                children: [
                  _OverviewTab(
                      state: state,
                    orders: orders,
                      isDark: isDark,
                      card: card,
                      border: border,
                      text: text,
                      sub: sub,
                      fmt: _fmt),
                  _OrdersTab(
                      state: state,
                    orders: orders,
                      isDark: isDark,
                      card: card,
                      border: border,
                      text: text,
                      sub: sub,
                      fmt: _fmt),
                  _CustomersTab(
                      state: state,
                      isDark: isDark,
                      card: card,
                      border: border,
                      text: text,
                      sub: sub,
                      fmt: _fmt),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════
// OVERVIEW TAB
// ═══════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final AnalyticsState state;
  final List<Order> orders;
  final bool isDark;
  final Color card, border, text, sub;
  final String Function(double) fmt;

  const _OverviewTab({
    required this.state,
    required this.orders,
    required this.isDark,
    required this.card,
    required this.border,
    required this.text,
    required this.sub,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _HeroCard(
          isDark: isDark,
          label: 'Total Revenue',
          value: fmt(stats?.totalRevenue ?? 0),
          sub: 'From ${stats?.totalOrders ?? 0} orders',
          icon: Icons.currency_rupee_rounded,
          color: KaapavTheme.gold,
        ),
        const SizedBox(height: 12),
        Row(children: [
          _MiniStat(
              label: 'Orders',
              value: '${stats?.totalOrders ?? 0}',
              color: const Color(0xFF3B82F6),
              card: card,
              border: border,
              text: text,
              sub: sub),
          const SizedBox(width: 10),
          _MiniStat(
              label: 'Customers',
              value: '${stats?.totalCustomers ?? 0}',
              color: const Color(0xFF8B5CF6),
              card: card,
              border: border,
              text: text,
              sub: sub),
          const SizedBox(width: 10),
          _MiniStat(
              label: 'Products',
              value: '${stats?.totalProducts ?? 0}',
              color: const Color(0xFF10B981),
              card: card,
              border: border,
              text: text,
              sub: sub),
          const SizedBox(width: 10),
          _MiniStat(
              label: 'Pending',
              value: '${stats?.pendingOrders ?? 0}',
              color: const Color(0xFFF59E0B),
              card: card,
              border: border,
              text: text,
              sub: sub),
        ]),
        const SizedBox(height: 20),
        _SectionTitle('Order Status Breakdown', text),
        const SizedBox(height: 10),
        _StatusBreakdown(
            orders: orders,
            card: card,
            border: border,
            text: text,
            sub: sub
        ),
        const SizedBox(height: 20),
        _SectionTitle('Revenue Split', text),
        const SizedBox(height: 10),
        _RevenueSplit(
            stats: stats,
            card: card,
            border: border,
            text: text,
            sub: sub,
            fmt: fmt),
        const SizedBox(height: 20),
        if (state.activities.isNotEmpty) ...[
          _SectionTitle('Recent Activity', text),
          const SizedBox(height: 10),
          _ActivityList(
              activities: state.activities,
              card: card,
              border: border,
              text: text,
              sub: sub,
              isDark: isDark),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════
// ORDERS TAB
// ═══════════════════════════════════════
class _OrdersTab extends StatelessWidget {
  final AnalyticsState state;
  final List<Order> orders;
  final bool isDark;
  final Color card, border, text, sub;
  final String Function(double) fmt;

  const _OrdersTab({
    required this.state,
    required this.orders,
    required this.isDark,
    required this.card,
    required this.border,
    required this.text,
    required this.sub,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final pending = state.pending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(children: [
          Expanded(
              child: _KpiCard(
            label: 'Total Orders',
            value: '${stats?.totalOrders ?? 0}',
            icon: Icons.shopping_bag_rounded,
            color: const Color(0xFF3B82F6),
            card: card,
            border: border,
            text: text,
            sub: sub,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _KpiCard(
            label: "Today's Orders",
            value: '${stats?.todayOrders ?? 0}',
            icon: Icons.today_rounded,
            color: KaapavTheme.gold,
            card: card,
            border: border,
            text: text,
            sub: sub,
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _KpiCard(
            label: 'Pending',
            value: '${stats?.pendingOrders ?? 0}',
            icon: Icons.hourglass_empty_rounded,
            color: const Color(0xFFF59E0B),
            card: card,
            border: border,
            text: text,
            sub: sub,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _KpiCard(
            label: 'Revenue',
            value: fmt(stats?.totalRevenue ?? 0),
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF10B981),
            card: card,
            border: border,
            text: text,
            sub: sub,
          )),
        ]),
        const SizedBox(height: 20),
        if (pending != null) ...[
          _SectionTitle('Pending Actions', text),
          const SizedBox(height: 10),
          _PendingBreakdown(
              pending: pending,
              card: card,
              border: border,
              text: text,
              sub: sub),
          const SizedBox(height: 20),
        ],
        _SectionTitle('Order Pipeline', text),
        const SizedBox(height: 10),
        _OrderPipeline(
          orders: orders,
            card: card,
            border: border,
            text: text,
            sub: sub),
        const SizedBox(height: 20),
        _SectionTitle('Payment Status', text),
        const SizedBox(height: 10),
        _PaymentStatus(
          orders: orders,
            card: card,
            border: border,
            text: text,
            sub: sub,
            fmt: fmt),
      ],
    );
  }
}

// ═══════════════════════════════════════
// CUSTOMERS TAB
// ═══════════════════════════════════════
class _CustomersTab extends StatelessWidget {
  final AnalyticsState state;
  final bool isDark;
  final Color card, border, text, sub;
  final String Function(double) fmt;

  const _CustomersTab({
    required this.state,
    required this.isDark,
    required this.card,
    required this.border,
    required this.text,
    required this.sub,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _HeroCard(
          isDark: isDark,
          label: 'Total Customers',
          value: '${stats?.totalCustomers ?? 0}',
          sub: 'Lifetime',
          icon: Icons.people_rounded,
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 20),
        _SectionTitle('Customer Insights', text),
        const SizedBox(height: 10),
        _InsightRow(
          label: 'Avg Order Value',
          value: stats != null && stats.totalOrders > 0
              ? fmt(stats.totalRevenue / stats.totalOrders)
              : '₹0',
          icon: Icons.shopping_cart_checkout_rounded,
          color: KaapavTheme.gold,
          card: card,
          border: border,
          text: text,
          sub: sub,
        ),
        const SizedBox(height: 8),
        _InsightRow(
          label: 'Active Chats',
          value: '${stats?.activeChats ?? 0}',
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF10B981),
          card: card,
          border: border,
          text: text,
          sub: sub,
        ),
        const SizedBox(height: 8),
        _InsightRow(
          label: 'Unread Messages',
          value: '${stats?.unreadMessages ?? 0}',
          icon: Icons.mark_unread_chat_alt_rounded,
          color: const Color(0xFFEF4444),
          card: card,
          border: border,
          text: text,
          sub: sub,
        ),
        const SizedBox(height: 8),
        _InsightRow(
          label: 'Revenue per Customer',
          value: stats != null && stats.totalCustomers > 0
              ? fmt(stats.totalRevenue / stats.totalCustomers)
              : '₹0',
          icon: Icons.currency_rupee_rounded,
          color: const Color(0xFF3B82F6),
          card: card,
          border: border,
          text: text,
          sub: sub,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Catalogue', text),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _KpiCard(
            label: 'Active Products',
            value: '${stats?.totalProducts ?? 0}',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF10B981),
            card: card,
            border: border,
            text: text,
            sub: sub,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _KpiCard(
            label: 'Inventory Value',
            value: fmt(stats?.inventoryValue ?? 0),
            icon: Icons.store_rounded,
            color: KaapavTheme.gold,
            card: card,
            border: border,
            text: text,
            sub: sub,
          )),
        ]),
      ],
    );
  }
}

// ═══════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle(this.title, this.color);

  @override
  Widget build(BuildContext context) => Text(title,
      style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: color));
}

class _HeroCard extends StatelessWidget {
  final bool isDark;
  final String label, value, sub;
  final IconData icon;
  final Color color;

  const _HeroCard(
      {required this.isDark,
      required this.label,
      required this.value,
      required this.sub,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 6),
                  Text(value,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF))),
                ]),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ]),
      );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color, card, border, text, sub;

  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.card,
      required this.border,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 9, color: sub)),
          ]),
        ),
      );
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, card, border, text, sub;

  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.card,
      required this.border,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: text)),
                Text(label,
                    style: TextStyle(fontSize: 10, color: sub)),
              ])),
        ]),
      );
}

class _InsightRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, card, border, text, sub;

  const _InsightRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.card,
      required this.border,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: text))),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      );
}

class _StatusBreakdown extends StatelessWidget {
  final List<Order> orders;
  final Color card, border, text, sub;

  const _StatusBreakdown({
    required this.orders,
    required this.card,
    required this.border,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      _SB('Pending', orders.where((o) => o.status == 'pending').length,
          const Color(0xFFF59E0B)),
      _SB('Confirmed', orders.where((o) => o.status == 'confirmed').length,
          const Color(0xFF3B82F6)),
      _SB('Processing', orders.where((o) => o.status == 'processing').length,
          const Color(0xFF8B5CF6)),
      _SB('Shipped', orders.where((o) => o.status == 'shipped').length,
          const Color(0xFF06B6D4)),
      _SB('Delivered', orders.where((o) => o.status == 'delivered').length,
          const Color(0xFF10B981)),
      _SB('Cancelled', orders.where((o) => o.status == 'cancelled').length,
          const Color(0xFFEF4444)),
    ];

    final total = statuses.fold<int>(0, (s, e) => s + e.count);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: statuses.map((s) {
          final pct = total > 0 ? s.count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(s.label, style: TextStyle(fontSize: 12, color: text)),
                    const Spacer(),
                    Text(
                      '${s.count}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: s.color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(s.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SB {
  final String label;
  final int count;
  final Color color;
  const _SB(this.label, this.count, this.color);
}

class _RevenueSplit extends StatelessWidget {
  final DashboardStats? stats;
  final Color card, border, text, sub;
  final String Function(double) fmt;

  const _RevenueSplit(
      {required this.stats,
      required this.card,
      required this.border,
      required this.text,
      required this.sub,
      required this.fmt});

  @override
  Widget build(BuildContext context) {
    final total = stats?.totalRevenue ?? 0;
    final today = stats?.todayRevenue ?? 0;
    final rest = total - today;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(children: [
        _RevenueRow('Today', today, total, KaapavTheme.gold,
            text, sub, fmt),
        const SizedBox(height: 10),
        _RevenueRow('Previous', rest, total,
            const Color(0xFF3B82F6), text, sub, fmt),
      ]),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color, text, sub;
  final String Function(double) fmt;

  const _RevenueRow(this.label, this.value, this.total,
      this.color, this.text, this.sub, this.fmt);

  @override
  Widget build(BuildContext context) {
    final pct =
        total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      Row(children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: text)),
        const Spacer(),
        Text(fmt(value),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 7,
        ),
      ),
    ]);
  }
}

class _ActivityList extends StatelessWidget {
  final List<Activity> activities;
  final Color card, border, text, sub;
  final bool isDark;

  const _ActivityList(
      {required this.activities,
      required this.card,
      required this.border,
      required this.text,
      required this.sub,
      required this.isDark});

  String _timeAgo(String ts) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(ts));
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              activities.length > 6 ? 6 : activities.length,
          separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF3F4F6)),
          itemBuilder: (_, i) {
            final a = activities[i];
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 11),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: KaapavTheme.gold
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                      Icons.notifications_outlined,
                      color: KaapavTheme.gold,
                      size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                        a.title ??
                            a.phone ??
                            'Activity',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (a.description != null)
                      Text(a.description!,
                          style: TextStyle(
                              fontSize: 11, color: sub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                )),
                Text(
                    a.timestamp != null
                        ? _timeAgo(a.timestamp!)
                        : '',
                    style:
                        TextStyle(fontSize: 10, color: sub)),
              ]),
            );
          },
        ),
      );
}

class _PendingBreakdown extends StatelessWidget {
  final PendingActions pending;
  final Color card, border, text, sub;

  const _PendingBreakdown(
      {required this.pending,
      required this.card,
      required this.border,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    final items = [
      _PB('Awaiting Confirmation',
          pending.pendingConfirmations,
          const Color(0xFFD97706),
          Icons.check_circle_outline),
      _PB('Unpaid Orders', pending.pendingPayments,
          const Color(0xFFEF4444), Icons.payment_rounded),
      _PB('Ready to Ship', pending.pendingShipments,
          const Color(0xFF0891B2),
          Icons.local_shipping_outlined),
      _PB('Abandoned Carts', pending.abandonedCarts,
          const Color(0xFF8B5CF6),
          Icons.shopping_cart_outlined),
    ].where((e) => e.count > 0).toList();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Text('All clear! No pending actions.',
              style: TextStyle(color: text, fontSize: 13)),
        ]),
      );
    }

    return Column(
      children: items
          .map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                      left: BorderSide(
                          color: e.color, width: 3)),
                ),
                child: Row(children: [
                  Icon(e.icon, color: e.color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(e.label,
                          style: TextStyle(
                              fontSize: 13, color: text))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: e.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${e.count}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: e.color)),
                  ),
                ]),
              ))
          .toList(),
    );
  }
}

class _PB {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _PB(this.label, this.count, this.color, this.icon);
}

class _OrderPipeline extends StatelessWidget {
  final List<Order> orders;
  final Color card, border, text, sub;

  const _OrderPipeline({
    required this.orders,
    required this.card,
    required this.border,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      _Stage('Pending', orders.where((o) => o.status == 'pending').length,
          const Color(0xFFF59E0B)),
      _Stage('Confirmed', orders.where((o) => o.status == 'confirmed').length,
          const Color(0xFF3B82F6)),
      _Stage('Processing', orders.where((o) => o.status == 'processing').length,
          const Color(0xFF8B5CF6)),
      _Stage('Shipped', orders.where((o) => o.status == 'shipped').length,
          const Color(0xFF06B6D4)),
      _Stage('Delivered', orders.where((o) => o.status == 'delivered').length,
          const Color(0xFF10B981)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: stages.asMap().entries.map((e) {
          final idx = e.key;
          final stage = e.value;

          return Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: stage.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: stage.color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${stage.count}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: stage.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stage.label,
                        style: TextStyle(fontSize: 8, color: sub),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (idx < stages.length - 1)
                  Icon(Icons.arrow_forward_ios, size: 10, color: sub),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Stage {
  final String label;
  final int count;
  final Color color;
  const _Stage(this.label, this.count, this.color);
}

class _PaymentStatus extends StatelessWidget {
  final List<Order> orders;
  final Color card, border, text, sub;
  final String Function(double) fmt;

  const _PaymentStatus({
    required this.orders,
    required this.card,
    required this.border,
    required this.text,
    required this.sub,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final paid = orders
        .where((o) => o.paymentStatus == 'paid')
        .fold<double>(0, (s, o) => s + o.total);

    final unpaid = orders
        .where((o) => o.paymentStatus == 'unpaid')
        .fold<double>(0, (s, o) => s + o.total);

    final refunded = orders
        .where((o) => o.paymentStatus == 'refunded')
        .fold<double>(0, (s, o) => s + o.total);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PayChip(
              'Paid',
              fmt(paid),
              const Color(0xFF10B981),
              text,
              sub,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PayChip(
              'Unpaid',
              fmt(unpaid),
              const Color(0xFFEF4444),
              text,
              sub,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PayChip(
              'Refunded',
              fmt(refunded),
              const Color(0xFFF59E0B),
              text,
              sub,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  final String label, value;
  final Color color, text, sub;

  const _PayChip(
      this.label, this.value, this.color, this.text, this.sub);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: sub)),
        ]),
      );
}