import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/order_provider.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final unreadTotal = ref.watch(chatProvider).unreadTotal;
    final pendingOrders = ref.watch(orderProvider).pendingCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 0,
              ),
              _NavItem(
                icon: Icons.chat_rounded,
                label: 'Chats',
                isActive: currentIndex == 1,
                badge: unreadTotal,
                onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
              ),
              _NavItem(
                icon: Icons.shopping_bag_rounded,
                label: 'Orders',
                isActive: currentIndex == 2,
                badge: pendingOrders,
                badgeColor: const Color(0xFFD97706),
                onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'Products',
                isActive: currentIndex == 3,
                onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 3,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'More',
                isActive: currentIndex == 4,
                onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 4,
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
  final Color? badgeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badge = 0,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive
                      ? KaapavTheme.gold
                      : const Color(0xFF9CA3AF),
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (badgeColor ?? const Color(0xFFEF4444))
                                .withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 14,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? KaapavTheme.gold
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}