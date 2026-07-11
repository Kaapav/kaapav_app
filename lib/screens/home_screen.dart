// lib/screens/home_screen.dart
// -----------------------------------------------------------
// MAIN TAB CONTAINER   5 tabs matching your PWA
// -----------------------------------------------------------
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaapav_app/config/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/order_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api/api_client.dart';
import 'owner_inbox/owner_inbox_screen.dart';
import 'dashboard_screen.dart';
import 'chats/chats_screen.dart';
import 'orders/orders_screen.dart';
import 'products/products_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 1; // Default to Chats
  int _ownerUnread = 0;
  late final PageController _pageController;

  final _screens = const [
    DashboardScreen(),
    ChatsScreen(),
    OrdersScreen(),
    ProductsScreen(),
    OwnerInboxScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    ref.read(chatProvider.notifier).loadChats();
    ref.read(orderProvider.notifier).loadOrders();
    ref.read(analyticsProvider.notifier).loadDashboard();
    ref.read(settingsProvider.notifier).loadAll();
    _loadOwnerInboxUnread();

    ref.read(chatProvider.notifier).startAutoRefresh();
    ref.read(analyticsProvider.notifier).startSync();
  }

  Future<void> _loadOwnerInboxUnread() async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/owner-inbox',
        queryParameters: {'limit': 1},
      );

      final unread = int.tryParse('${res.data['unread'] ?? 0}') ?? 0;

      if (!mounted) return;

      setState(() {
        _ownerUnread = unread;
      });
    } catch (_) {
      // Silent fail. Owner Inbox screen will show API error if needed.
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    try {
      ref.read(chatProvider.notifier).stopAutoRefresh();
      ref.read(analyticsProvider.notifier).stopSync();
    } catch (_) {}
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);

    if (index == 4) {
      _loadOwnerInboxUnread();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadTotal = ref.watch(chatProvider.select((s) => s.unreadTotal));
    final pendingOrders = ref.watch(orderProvider.select((s) => s.pendingCount));

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        unreadCount: unreadTotal,
        pendingOrders: pendingOrders,
        ownerUnread: _ownerUnread,
      ),
    );
  }
}

// -----------------------------------------------------------
// BOTTOM NAVIGATION BAR
// Matches your PWA: Dashboard, Chats, Orders, Products, Settings
// -----------------------------------------------------------

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;
  final int pendingOrders;
  final int ownerUnread;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.unreadCount,
    required this.pendingOrders,
    required this.ownerUnread,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.105),
                  KaapavTheme.gold.withValues(alpha: 0.070),
                  Colors.black.withValues(alpha: 0.220),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 30,
                  spreadRadius: -8,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: KaapavTheme.gold.withValues(alpha: 0.16),
                  blurRadius: 34,
                  spreadRadius: -12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  accent: KaapavTheme.gold,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  isActive: currentIndex == 1,
                  accent: KaapavTheme.teal,
                  badge: unreadCount,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Orders',
                  isActive: currentIndex == 2,
                  accent: KaapavTheme.amethyst,
                  badge: pendingOrders,
                  onTap: () => onTap(2),
                ),
_NavItem(
  icon: Icons.inventory_2_rounded,
  label: 'Items',
  isActive: currentIndex == 3,
  accent: KaapavTheme.rose,
  onTap: () => onTap(3),
),
_NavItem(
  icon: Icons.notifications_active_rounded,
  label: 'Alerts',
  isActive: currentIndex == 4,
  accent: KaapavTheme.gold,
  badge: ownerUnread,
  onTap: () => onTap(4),
),
_NavItem(
  icon: Icons.settings_rounded,
  label: 'More',
  isActive: currentIndex == 5,
  accent: KaapavTheme.sapphire,
  onTap: () => onTap(5),
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badge;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accent,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 58,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.085),
                      Colors.black.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive
                  ? accent.withValues(alpha: 0.42)
                  : Colors.transparent,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: isActive ? 1.08 : 1.0,
                    child: Icon(
                      icon,
                      size: 23,
                      color: isActive
                          ? accent
                          : KaapavTheme.grayLight.withValues(alpha: 0.82),
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: KaapavTheme.dangerGradient,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: KaapavTheme.bgDeep,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: KaapavTheme.rose.withValues(alpha: 0.34),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: KaapavTheme.white,
                            fontSize: 9,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? KaapavTheme.white
                      : KaapavTheme.grayLight.withValues(alpha: 0.75),
                  letterSpacing: isActive ? 0.05 : 0,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
