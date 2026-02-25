// lib/widgets/quick_replies.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../models/quick_reply.dart';

class QuickReplies extends StatelessWidget {
  final List<QuickReply> replies;
  final Function(QuickReply reply) onSelect;

  const QuickReplies({super.key, required this.replies, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(reply: reply, onTap: () { HapticFeedback.lightImpact(); onSelect(reply); }),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final QuickReply reply;
  final VoidCallback onTap;
  const _Chip({required this.reply, required this.onTap});

  String _getTitle() {
    if (reply.title.isNotEmpty) return reply.title;
    if (reply.message.isNotEmpty) return reply.message;
    return 'Reply';
  }

  @override
  Widget build(BuildContext context) {
    final shortcut = reply.shortcut;
    final title = _getTitle();
    final hasShortcut = shortcut.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: KaapavTheme.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KaapavTheme.gold.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasShortcut) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: KaapavTheme.cream, borderRadius: BorderRadius.circular(4)),
                  child: Text('/$shortcut', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
                ),
                const SizedBox(width: 8),
              ],
              Text(title.length > 20 ? '${title.substring(0, 20)}...' : title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: KaapavTheme.dark)),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleQuickReplies extends StatelessWidget {
  final List<String> replies;
  final Function(String reply) onSelect;
  const SimpleQuickReplies({super.key, required this.replies, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () { HapticFeedback.lightImpact(); onSelect(reply); },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: KaapavTheme.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KaapavTheme.gold.withOpacity(0.5)),
                  ),
                  child: Text(reply, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: KaapavTheme.dark)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}