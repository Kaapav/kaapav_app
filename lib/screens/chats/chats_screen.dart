// lib/screens/chats/chats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});
  @override ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadChats();
      ref.read(chatProvider.notifier).startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);
    final filtered = chatState.chats.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.customerName.toLowerCase().contains(q) || c.phone.contains(q) || (c.lastMessage?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        title: Text('Chats', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          if (chatState.unreadTotal > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: KaapavTheme.gold, borderRadius: BorderRadius.circular(12)),
              child: Text('${chatState.unreadTotal} unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
            onPressed: () => ref.read(chatProvider.notifier).loadChats(),
          ),
        ],
      ),
      body: Column(children: [
        // Search
        Container(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search chats...', hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
              filled: true, fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        // List
        Expanded(child: chatState.isLoading && chatState.chats.isEmpty
          ? const Center(child: CircularProgressIndicator(color: KaapavTheme.gold))
          : chatState.error != null && chatState.chats.isEmpty
            ? _ErrorView(onRetry: () => ref.read(chatProvider.notifier).loadChats())
            : filtered.isEmpty ? _EmptyView(hasQuery: _query.isNotEmpty)
            : RefreshIndicator(
                color: KaapavTheme.gold,
                onRefresh: () => ref.read(chatProvider.notifier).loadChats(),
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB), indent: 76),
                  itemBuilder: (_, i) => _ChatTile(chat: filtered[i]),
                ),
              ),
        ),
      ]),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = chat.unreadCount > 0;
    return InkWell(
      onTap: () {
        ref.read(chatProvider.notifier).markRead(chat.phone);
        AppRoutes.openChat(context, chat.phone, name: chat.customerName);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isUnread ? KaapavTheme.gold.withOpacity(isDark ? 0.05 : 0.03) : Colors.transparent,
        child: Row(children: [
          _Avatar(name: chat.customerName, isUnread: isUnread),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(
                chat.customerName.isNotEmpty ? chat.customerName : chat.phone,
                style: TextStyle(fontSize: 15, fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
              if (chat.lastTimestamp != null)
                Text(_formatTime(chat.lastTimestamp!), style: TextStyle(fontSize: 12, color: isUnread ? KaapavTheme.gold : const Color(0xFF9CA3AF), fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              if (chat.lastDirection == 'outgoing')
                const Padding(padding: EdgeInsets.only(right: 3), child: Icon(Icons.done_all, size: 14, color: Color(0xFF9CA3AF))),
              Expanded(child: Text(_previewText(), style: TextStyle(fontSize: 13, color: isUnread ? (isDark ? Colors.white70 : const Color(0xFF374151)) : const Color(0xFF9CA3AF), fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: KaapavTheme.gold, borderRadius: BorderRadius.circular(10)),
                  child: Text(chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ]),
            if (chat.labels.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 4, children: chat.labels.take(3).map((l) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: KaapavTheme.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(l, style: const TextStyle(fontSize: 10, color: KaapavTheme.gold, fontWeight: FontWeight.w500)),
              )).toList())),
          ])),
        ]),
      ),
    );
  }

  String _previewText() {
    if (chat.lastMessage?.isNotEmpty == true) return chat.lastMessage!;
    switch (chat.lastMessageType) {
      case 'image': return '📷 Photo';
      case 'video': return '🎥 Video';
      case 'audio': return '🎵 Audio';
      case 'document': return '📄 Document';
      default: return 'Tap to open chat';
    }
  }

  String _formatTime(String ts) {
    try { return timeago.format(DateTime.parse(ts).toLocal(), locale: 'en_short'); } catch (_) { return ''; }
  }
}

class _Avatar extends StatelessWidget {
  final String name; final bool isUnread;
  const _Avatar({required this.name, required this.isUnread});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUnread ? KaapavTheme.goldGradient : const LinearGradient(colors: [Color(0xFF374151), Color(0xFF1F2937)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: isUnread ? [BoxShadow(color: KaapavTheme.gold.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
      ),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasQuery; const _EmptyView({required this.hasQuery});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(hasQuery ? Icons.search_off : Icons.chat_bubble_outline, size: 64, color: const Color(0xFF9CA3AF)),
    const SizedBox(height: 16),
    Text(hasQuery ? 'No chats match your search' : 'No chats yet', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
    if (!hasQuery) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Messages from WhatsApp will appear here', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))),
  ]));
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry; const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off, size: 64, color: Color(0xFF9CA3AF)),
    const SizedBox(height: 16),
    const Text('Could not load chats', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
    const SizedBox(height: 12),
    ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'), style: ElevatedButton.styleFrom(backgroundColor: KaapavTheme.gold, foregroundColor: Colors.white)),
  ]));
}