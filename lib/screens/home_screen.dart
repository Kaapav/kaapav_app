// lib/screens/home_screen.dart
// ═══════════════════════════════════════════════════════════
// MAIN TAB CONTAINER — 5 tabs matching your PWA
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/order_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/settings_provider.dart';
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
  int _currentIndex = 1; // Default to Chats (like your PWA defaults to /chats)
  late final PageController _pageController;

  final _screens = const [
    DashboardScreen(),
    ChatsScreen(),
    OrdersScreen(),
    ProductsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    ref.read(chatProvider.notifier).loadChats();
    ref.read(orderProvider.notifier).loadOrders();
    ref.read(analyticsProvider.notifier).loadDashboard();
    ref.read(settingsProvider.notifier).loadAll();

    // Start auto-refresh for chats
    ref.read(chatProvider.notifier).startAutoRefresh();
    // Start sync polling
    ref.read(analyticsProvider.notifier).startSync();
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
      // Double tap — scroll to top / refresh
      return;
    }
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final unreadTotal = ref.watch(chatProvider.select((s) => s.unreadTotal));
    final pendingOrders = ref.watch(orderProvider.select((s) => s.pendingCount));

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // No swipe between tabs
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        unreadCount: unreadTotal,
        pendingOrders: pendingOrders,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BOTTOM NAVIGATION BAR
// Matches your PWA: Dashboard, Chats, Orders, Products, Settings
// ═══════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;
  final int pendingOrders;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.unreadCount,
    required this.pendingOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KaapavColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chats',
                isActive: currentIndex == 1,
                badge: unreadCount,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.shopping_bag_rounded,
                label: 'Orders',
                isActive: currentIndex == 2,
                badge: pendingOrders,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'Products',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? KaapavColors.gold.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? KaapavColors.gold : KaapavColors.grayLight,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KaapavColors.error,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: KaapavColors.error.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: KaapavColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? KaapavColors.gold : KaapavColors.grayLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}