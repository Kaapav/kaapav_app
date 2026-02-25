// lib/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/analytics_provider.dart';
import '../config/routes_args.dart';
import '../widgets/common/shimmer_loading.dart';
import '../models/analytics_model.dart';

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
    Future.microtask(() {
      ref.read(analyticsProvider.notifier).loadDashboard();
    });
    // Auto refresh every 30 seconds like PWA
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _timeAgo(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
      final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111111) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: state.isLoading && state.stats == null
            ? const ShimmerLoading(type: ShimmerType.dashboard)
            : RefreshIndicator(
                color: KaapavTheme.gold,
                onRefresh: () => ref.read(analyticsProvider.notifier).loadDashboard(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    // ═══════════════════════════════════════════
                    // HEADER
                    // ═══════════════════════════════════════════
                    _buildHeader(isDark),
                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════
                    // STATS GRID (4 cards)
                    // ═══════════════════════════════════════════
                    _buildStatsGrid(state.stats, isDark),
                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════
                    // PENDING ACTIONS
                    // ═══════════════════════════════════════════
                    if (state.pending != null && state.pending!.total > 0)
                      _buildPendingActions(state.pending!, isDark),

                    // ═══════════════════════════════════════════
                    // LIVE ACTIVITY
                    // ═══════════════════════════════════════════
                    if (state.activities.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildLiveActivity(state.activities, isDark),
                    ],

                    // ═══════════════════════════════════════════
                    // QUICK ACTIONS
                    // ═══════════════════════════════════════════
                    const SizedBox(height: 20),
                    _buildQuickActions(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER — Greeting + Avatar
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()} 👋',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'KAAPAV',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: KaapavTheme.gold.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATS GRID — 4 cards matching PWA exactly
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsGrid(DashboardStats? stats, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.chat_bubble_rounded,
          iconColor: const Color(0xFF10B981),
          value: '${stats?.activeChats ?? 0}',
          label: 'Active Chats',
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.chats),
        ),
        _StatCard(
          icon: Icons.currency_rupee,
          iconColor: KaapavTheme.gold,
          value: _formatCurrency(stats?.todayRevenue ?? 0),
          label: "Today's Revenue",
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
        ),
        _StatCard(
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF3B82F6),
          value: '${stats?.todayOrders ?? 0}',
          label: 'New Orders',
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
        ),
        _StatCard(
          icon: Icons.people_rounded,
          iconColor: const Color(0xFF8B5CF6),
          value: '${stats?.totalCustomers ?? 0}',
          label: 'Customers',
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PENDING ACTIONS — Urgent items matching PWA
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPendingActions(PendingActions pending, bool isDark) {
    final items = <_PendingItem>[];

    if (pending.pendingConfirmations > 0) {
      items.add(_PendingItem(
        icon: Icons.check_circle_outline,
        color: const Color(0xFFD97706),
        count: pending.pendingConfirmations,
        text: 'orders awaiting confirmation',
        route: AppRoutes.orders,
      ));
    }
    if (pending.pendingPayments > 0) {
      items.add(_PendingItem(
        icon: Icons.payment,
        color: const Color(0xFFEF4444),
        count: pending.pendingPayments,
        text: 'unpaid orders',
        route: AppRoutes.orders,
      ));
    }
    if (pending.pendingShipments > 0) {
      items.add(_PendingItem(
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF0891B2),
        count: pending.pendingShipments,
        text: 'orders ready to ship',
        route: AppRoutes.orders,
      ));
    }
    if (pending.abandonedCarts > 0) {
      items.add(_PendingItem(
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF8B5CF6),
        count: pending.abandonedCarts,
        text: 'abandoned carts',
        route: AppRoutes.chats,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '⚡ Pending Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KaapavTheme.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildPendingTile(item, isDark)),
      ],
    );
  }

  Widget _buildPendingTile(_PendingItem item, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: item.color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.count} ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    TextSpan(
                      text: item.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LIVE ACTIVITY — Recent events
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLiveActivity(List<Activity> activities, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📡 Live Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 10 ? 10 : activities.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
            ),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityTile(activity, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(Activity activity, bool isDark) {
    final config = _getActivityConfig(activity.type);

    return InkWell(
      onTap: () {
        if (activity.phone != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.chatWindow,
            arguments: ChatWindowArgs(phone: activity.phone!),
          );
        } else if (activity.orderId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.orderDetail,
            arguments: activity.orderId,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(config.icon, color: config.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title ?? activity.type ?? 'Activity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (activity.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      activity.description!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeAgo(activity.timestamp),
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  ActivityConfig _getActivityConfig(String? type) {
    switch (type) {
      case 'message':
        return ActivityConfig(Icons.chat_bubble_outline, const Color(0xFF10B981));
      case 'order':
        return ActivityConfig(Icons.shopping_bag_outlined, const Color(0xFF3B82F6));
      case 'payment':
        return ActivityConfig(Icons.payment, const Color(0xFFF59E0B));
      case 'customer':
        return ActivityConfig(Icons.person_outline, const Color(0xFF8B5CF6));
      case 'product':
        return ActivityConfig(Icons.inventory_2_outlined, const Color(0xFF0891B2));
      default:
        return ActivityConfig(Icons.notifications_outlined, const Color(0xFF6B7280));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK ACTIONS — 4 buttons matching PWA
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🚀 Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionButton(
              icon: Icons.campaign_rounded,
              label: 'Broadcast',
              isDark: isDark,
              onTap: () => Navigator.pushNamed(context, AppRoutes.broadcasts),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.add_shopping_cart,
              label: 'New Order',
              isDark: isDark,
              onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.inventory_2_rounded,
              label: 'Products',
              isDark: isDark,
              onTap: () => Navigator.pushNamed(context, AppRoutes.products),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.bar_chart_rounded,
              label: 'Analytics',
              isDark: isDark,
              onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT CARD WIDGET
// ═══════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK ACTION BUTTON
// ═══════════════════════════════════════════════════════════════
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KaapavTheme.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: KaapavTheme.gold, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════
class _PendingItem {
  final IconData icon;
  final Color color;
  final int count;
  final String text;
  final String route;

  const _PendingItem({
    required this.icon,
    required this.color,
    required this.count,
    required this.text,
    required this.route,
  });
}