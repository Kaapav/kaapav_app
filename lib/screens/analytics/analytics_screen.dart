import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A), elevation: 0),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: KaapavTheme.gold))
          : RefreshIndicator(
              color: KaapavTheme.gold,
              onRefresh: () => ref.read(analyticsProvider.notifier).loadDashboard(),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Text('Coming Soon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                const Text('Detailed analytics will be available here.',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ]),
            ),
    );
  }
}