import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../providers/message_provider.dart';
import '../../widgets/chat_bubble.dart';

class StarredMessagesScreen extends ConsumerWidget {
  const StarredMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starred = ref.watch(starredMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: KaapavTheme.white,
        title: const Text('Starred Messages', style: TextStyle(color: KaapavTheme.dark, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: starred.isEmpty
          ? const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.star_border, size: 64, color: KaapavTheme.grayLight),
                SizedBox(height: 16),
                Text('No starred messages', style: TextStyle(color: KaapavTheme.gray, fontSize: 16)),
              ]),
            )
          : ListView.builder(
              itemCount: starred.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (_, i) {
                final entry = starred[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(entry.phone, style: const TextStyle(fontSize: 12, color: KaapavTheme.gold, fontWeight: FontWeight.w600)),
                    ),
                    ChatBubble(message: entry),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
    );
  }
}