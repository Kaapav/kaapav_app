import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/broadcast_provider.dart';
import '../../widgets/common/empty_state.dart';

class BroadcastsScreen extends ConsumerStatefulWidget {
  const BroadcastsScreen({super.key});

  @override
  ConsumerState<BroadcastsScreen> createState() => _BroadcastsScreenState();
}

class _BroadcastsScreenState extends ConsumerState<BroadcastsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(broadcastProvider.notifier).loadBroadcasts());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(broadcastProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Broadcasts'),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A), elevation: 0),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: KaapavTheme.gold))
          : state.broadcasts.isEmpty
              ? const EmptyState(icon: Icons.campaign_outlined, title: 'No broadcasts yet')
              : RefreshIndicator(
                  color: KaapavTheme.gold,
                  onRefresh: () => ref.read(broadcastProvider.notifier).loadBroadcasts(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.filteredBroadcasts.length,
                    itemBuilder: (_, i) {
                      final b = state.filteredBroadcasts[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E7EB)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(b.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A)))),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: KaapavTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(b.status, style: const TextStyle(fontSize: 11, color: KaapavTheme.gold, fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text('Target: ${b.targetCount}', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                            const SizedBox(width: 16),
                            Text('Sent: ${b.sentCount}', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                            const SizedBox(width: 16),
                            Text('Read: ${b.readCount}', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}