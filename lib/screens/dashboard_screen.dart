// lib/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaapav_app/config/theme.dart';
import '../config/routes.dart';
import '../config/routes_args.dart';
import '../providers/analytics_provider.dart';
import '../models/analytics_model.dart';
import '../widgets/common/shimmer_loading.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(analyticsProvider.notifier).loadDashboard());
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(analyticsProvider.notifier).refreshStats();
      ref.read(analyticsProvider.notifier).refreshPending();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _currency(double v) {
    if (v >= 100000) return '\u20B9${(v / 1000).toStringAsFixed(1)}K';
    if (v >= 1000)   return '\u20B9${(v / 1000).toStringAsFixed(1)}K';
    return '\u20B9${v.toStringAsFixed(0)}';
  }

  String _timeAgo(String? ts) {
    if (ts == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(ts));
      if (diff.inSeconds < 60)  return 'Just now';
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)    return '${diff.inHours}h ago';
      if (diff.inDays < 7)      return '${diff.inDays}d ago';
      final dt = DateTime.parse(ts);
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(analyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: state.isLoading && state.stats == null
            ? const ShimmerLoading(type: ShimmerType.dashboard)
            : RefreshIndicator(
                color: KaapavTheme.gold,
                onRefresh: () => ref.read(analyticsProvider.notifier).loadDashboard(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    _header(isDark, state.stats),
                    const SizedBox(height: 18),
                    _statsGrid(state.stats, isDark),
                    const SizedBox(height: 18),
                    _revenueStrip(state.stats, isDark),
                    if (state.pending != null && state.pending!.total > 0) ...[
                      const SizedBox(height: 18),
                      _pendingSection(state.pending!, isDark),
                    ],
                    if (state.activities.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _activitySection(state.activities, isDark),
                    ],
                    const SizedBox(height: 18),
                    _quickActions(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _header(bool isDark, DashboardStats? stats) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(),
                style: TextStyle(fontSize: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
              const SizedBox(height: 3),
              Row(children: [
                Text('KAAPAV',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(width: 8),
                if (stats != null && (stats.unreadMessages ) > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${stats.unreadMessages} new',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.notifications_outlined, size: 20)),
                if (stats != null && (stats.pendingOrders) > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Settings avatar
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: KaapavTheme.gold.withValues(alpha: 0.3),
                blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Center(
              child: Text('K', style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats Grid ────────────────────────────────────────────────
  Widget _statsGrid(DashboardStats? stats, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          icon: Icons.chat_bubble_rounded,
          iconColor: const Color(0xFF10B981),
          value: '${stats?.activeChats ?? 0}',
          label: 'Active Chats',
          subLabel: stats?.unreadMessages != null && stats!.unreadMessages > 0
              ? '${stats.unreadMessages} unread' : null,
          subColor: const Color(0xFF10B981),
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.chats),
        ),
        _StatCard(
          icon: Icons.currency_rupee_rounded,
          iconColor: KaapavTheme.gold,
          value: _currency(stats?.todayRevenue ?? 0),
          label: "Today's Revenue",
          subLabel: stats?.totalRevenue != null
              ? 'Total: ${_currency(stats!.totalRevenue)}' : null,
          subColor: const Color(0xFF9CA3AF),
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
        ),
        _StatCard(
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF3B82F6),
          value: '${stats?.todayOrders ?? 0}',
          label: 'New Orders',
          subLabel: stats?.pendingOrders != null && stats!.pendingOrders > 0
              ? '${stats.pendingOrders} pending' : null,
          subColor: const Color(0xFFF59E0B),
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
        ),
        _StatCard(
          icon: Icons.people_rounded,
          iconColor: const Color(0xFF8B5CF6),
          value: '${stats?.totalCustomers ?? 0}',
          label: 'Customers',
          subLabel: stats?.totalProducts != null
              ? '${stats!.totalProducts} products' : null,
          subColor: const Color(0xFF9CA3AF),
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
        ),
      ],
    );
  }

  // ── Revenue strip ─────────────────────────────────────────────
  Widget _revenueStrip(DashboardStats? stats, bool isDark) {
    if (stats == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KaapavTheme.gold.withValues(alpha: 0.15),
            KaapavTheme.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KaapavTheme.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: KaapavTheme.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Total revenue: ${_currency(stats.totalRevenue)}  •  '
              '${stats.totalOrders} orders  •  '
              '${stats.totalProducts} products active',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF374151)),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
            child: const Text('Details →',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: KaapavTheme.gold)),
          ),
        ],
      ),
    );
  }

  // ── Pending actions ───────────────────────────────────────────
  Widget _pendingSection(PendingActions pending, bool isDark) {
    final items = <_PendingItem>[];
    if (pending.pendingConfirmations > 0) items.add(_PendingItem(
      icon: Icons.check_circle_outline, color: const Color(0xFFD97706),
      count: pending.pendingConfirmations, text: 'orders awaiting confirmation',
      route: AppRoutes.orders));
    if (pending.pendingPayments > 0) items.add(_PendingItem(
      icon: Icons.payment, color: const Color(0xFFEF4444),
      count: pending.pendingPayments, text: 'unpaid orders',
      route: AppRoutes.orders));
    if (pending.pendingShipments > 0) items.add(_PendingItem(
      icon: Icons.local_shipping_outlined, color: const Color(0xFF0891B2),
      count: pending.pendingShipments, text: 'orders ready to ship',
      route: AppRoutes.orders));
    if (pending.abandonedCarts > 0) items.add(_PendingItem(
      icon: Icons.shopping_cart_outlined, color: const Color(0xFF8B5CF6),
      count: pending.abandonedCarts, text: 'abandoned carts',
      route: AppRoutes.chats));
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '⚡ Pending Actions',
          isDark: isDark,
          action: 'View All',
          onAction: () => Navigator.pushNamed(context, AppRoutes.orders),
        ),
        const SizedBox(height: 10),
        ...items.map((item) => _PendingTile(item: item, isDark: isDark,
          onTap: () => Navigator.pushNamed(context, item.route))),
      ],
    );
  }

  // ── Live activity ─────────────────────────────────────────────
  Widget _activitySection(List<Activity> activities, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '🔴 Live Activity',
          isDark: isDark,
          action: 'See All',
          onAction: () => Navigator.pushNamed(context, AppRoutes.chats),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE5E7EB)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 8 ? 8 : activities.length,
            separatorBuilder: (_, __) => Divider(height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF3F4F6)),
            itemBuilder: (_, i) => _ActivityTile(
              activity: activities[i],
              isDark: isDark,
              timeAgo: _timeAgo(activities[i].timestamp),
              onTap: () {
                if (activities[i].phone != null) {
                  Navigator.pushNamed(context, AppRoutes.chatWindow,
                    arguments: ChatWindowArgs(phone: activities[i].phone!));
                } else if (activities[i].orderId != null) {
                  Navigator.pushNamed(context, AppRoutes.orderDetail,
                    arguments: activities[i].orderId);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick actions ─────────────────────────────────────────────
  Widget _quickActions(bool isDark) {
    final actions = [
      _QA(Icons.campaign_rounded,        'Broadcast', AppRoutes.broadcasts),
      _QA(Icons.add_shopping_cart,       'New Order',  AppRoutes.orders),
      _QA(Icons.inventory_2_rounded,     'Products',  AppRoutes.products),
      _QA(Icons.bar_chart_rounded,       'Analytics', AppRoutes.analytics),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '⚡ Quick Actions', isDark: isDark),
        const SizedBox(height: 10),
        Row(
          children: actions.map((a) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: a == actions.last ? 0 : 10),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, a.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFE5E7EB)),
                  ),
                  child: Column(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: KaapavTheme.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon, color: KaapavTheme.gold, size: 19),
                    ),
                    const SizedBox(height: 7),
                    Text(a.label, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
                    ),
                  ]),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, required this.isDark,
    this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
      const Spacer(),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action!, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
        ),
    ],
  );
}

// ── Stat card ─────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? subLabel;
  final Color? subColor;
  final bool isDark;
  final VoidCallback? onTap;
  const _StatCard({required this.icon, required this.iconColor,
    required this.value, required this.label, required this.isDark,
    this.subLabel, this.subColor, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 9),
          Text(value, style: TextStyle(
            fontSize: 21, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(
            fontSize: 11, color: Color(0xFF9CA3AF))),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(subLabel!, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: subColor ?? const Color(0xFF9CA3AF))),
          ],
        ],
      ),
    ),
  );
}

// ── Pending tile ──────────────────────────────────────────────
class _PendingTile extends StatelessWidget {
  final _PendingItem item;
  final bool isDark;
  final VoidCallback onTap;
  const _PendingTile({required this.item, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border(left: BorderSide(color: item.color, width: 3)),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(item.icon, color: item.color, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: RichText(text: TextSpan(children: [
            TextSpan(text: '${item.count} ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            TextSpan(text: item.text,
              style: TextStyle(fontSize: 14,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
          ])),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
      ]),
    ),
  );
}

// ── Activity tile ─────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final Activity activity;
  final bool isDark;
  final String timeAgo;
  final VoidCallback onTap;
  const _ActivityTile({required this.activity, required this.isDark,
    required this.timeAgo, required this.onTap});

  static _ActivityConfig _config(String? type) {
    switch (type) {
      case 'message':  return _ActivityConfig(Icons.chat_bubble_outline,    const Color(0xFF10B981));
      case 'order':    return _ActivityConfig(Icons.shopping_bag_outlined,   const Color(0xFF3B82F6));
      case 'payment':  return _ActivityConfig(Icons.payment,                 const Color(0xFFF59E0B));
      case 'customer': return _ActivityConfig(Icons.person_outline,          const Color(0xFF8B5CF6));
      case 'product':  return _ActivityConfig(Icons.inventory_2_outlined,    const Color(0xFF0891B2));
      default:         return _ActivityConfig(Icons.notifications_outlined,  const Color(0xFF6B7280));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config(activity.type);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title ?? activity.type ?? 'Activity',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (activity.description != null)
                  Text(activity.description!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(timeAgo, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }
}

class _ActivityConfig {
  final IconData icon;
  final Color color;
  const _ActivityConfig(this.icon, this.color);
}

class _PendingItem {
  final IconData icon;
  final Color color;
  final int count;
  final String text;
  final String route;
  const _PendingItem({required this.icon, required this.color,
    required this.count, required this.text, required this.route});
}

class _QA {
  final IconData icon;
  final String label;
  final String route;
  const _QA(this.icon, this.label, this.route);
}

class ActivityConfig {
  final IconData icon;
  final Color color;
  const ActivityConfig(this.icon, this.color);
}