// lib/screens/chats/chats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kaapav_app/config/theme.dart';
import '../../config/routes.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import 'package:flutter/services.dart';
import '../../widgets/common/glass_shell.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/glass_app_bar.dart';
enum _InboxFilter { all, unread, pinned, botOff, hotLeads }

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});
  @override ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _InboxFilter _filter = _InboxFilter.all;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadChats();
      
    });
  }

@override
void dispose() {
  _searchCtrl.dispose();
  super.dispose();
}

  @override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final chatState = ref.watch(chatProvider);
  final pinnedSet = chatState.pinnedChats;

  final filtered = chatState.chats.where((c) {
    final q = _query.trim().toLowerCase();

    final matchesQuery = q.isEmpty ||
        c.customerName.toLowerCase().contains(q) ||
        c.phone.contains(q) ||
        (c.lastMessage?.toLowerCase().contains(q) ?? false);

    if (!matchesQuery) return false;

    switch (_filter) {
      case _InboxFilter.unread:
        return c.unreadCount > 0;
      case _InboxFilter.pinned:
        return pinnedSet.contains(c.phone);
      case _InboxFilter.botOff:
        return !c.isBotEnabled;
      case _InboxFilter.hotLeads:
        return c.labels.any((l) => l.toLowerCase().contains('hot'));
      case _InboxFilter.all:
        return true;
    }
  }).toList();

  filtered.sort((a, b) {
    final aPinned = pinnedSet.contains(a.phone);
    final bPinned = pinnedSet.contains(b.phone);

    if (aPinned && !bPinned) return -1;
    if (!aPinned && bPinned) return 1;

    final aTime = a.lastTimestamp ?? '';
    final bTime = b.lastTimestamp ?? '';

    return bTime.compareTo(aTime);
  });

  return Scaffold(
    backgroundColor: Colors.transparent,
    body: KaapavGlassShell(
      isDark: isDark,
      child: Column(
        children: [
          KaapavGlassAppBar(
            title: 'Chats',
            subtitle:
                '${filtered.length} conversations • ${chatState.unreadTotal} unread',
            isDark: isDark,
            actions: [
              if (chatState.unreadTotal > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: KaapavTheme.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${chatState.unreadTotal}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              KaapavGlassIconButton(
                icon: Icons.refresh_rounded,
                isDark: isDark,
                onTap: () => ref.read(chatProvider.notifier).loadChats(),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                KaapavGlassCard(
                  isDark: isDark,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  radius: 18,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search customer, phone, message...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF9CA3AF),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF9CA3AF),
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        icon: Icons.all_inbox_rounded,
                        selected: _filter == _InboxFilter.all,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _filter = _InboxFilter.all),
                      ),
                      _FilterChip(
                        label: 'Unread',
                        icon: Icons.mark_chat_unread_rounded,
                        selected: _filter == _InboxFilter.unread,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _filter = _InboxFilter.unread),
                      ),
                      _FilterChip(
                        label: 'Pinned',
                        icon: Icons.push_pin_rounded,
                        selected: _filter == _InboxFilter.pinned,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _filter = _InboxFilter.pinned),
                      ),
                      _FilterChip(
                        label: 'Bot Off',
                        icon: Icons.smart_toy_outlined,
                        selected: _filter == _InboxFilter.botOff,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _filter = _InboxFilter.botOff),
                      ),
                      _FilterChip(
                        label: 'Hot Leads',
                        icon: Icons.local_fire_department_rounded,
                        selected: _filter == _InboxFilter.hotLeads,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _filter = _InboxFilter.hotLeads),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: chatState.isLoading && chatState.chats.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: KaapavTheme.gold,
                    ),
                  )
                : chatState.error != null && chatState.chats.isEmpty
                    ? _ErrorView(
                        onRetry: () =>
                            ref.read(chatProvider.notifier).loadChats(),
                      )
                    : filtered.isEmpty
                        ? _EmptyView(hasQuery: _query.isNotEmpty)
                        : RefreshIndicator(
                            color: KaapavTheme.gold,
                            onRefresh: () =>
                                ref.read(chatProvider.notifier).loadChats(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _ChatTile(chat: filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    ),
  );
}
}
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? KaapavTheme.gold.withValues(alpha: 0.16)
        : isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.58);

    final border = selected
        ? KaapavTheme.gold.withValues(alpha: 0.38)
        : isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? KaapavTheme.gold : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? KaapavTheme.gold
                      : isDark
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);
    final isUnread = chat.unreadCount > 0;
    final isPinned = chatState.pinnedChats.contains(chat.phone);
    final isMuted = chatState.mutedChats.contains(chat.phone);

    return Dismissible(
      key: Key('chat_${chat.phone}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();

        if (direction == DismissDirection.startToEnd) {
          ref.read(chatProvider.notifier).togglePin(chat.phone);
          return false;
        }

        ref.read(chatProvider.notifier).toggleMute(chat.phone);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: KaapavTheme.gold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              color: KaapavTheme.gold,
            ),
            const SizedBox(width: 8),
            Text(
              isPinned ? 'Unpin' : 'Pin',
              style: const TextStyle(
                color: KaapavTheme.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMuted ? 'Unmute' : 'Mute',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isMuted ? Icons.notifications_rounded : Icons.notifications_off,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: KaapavGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(12),
          radius: 18,
          borderColor: isUnread
              ? KaapavTheme.gold.withValues(alpha: 0.26)
              : null,
          onTap: () {
            ref.read(chatProvider.notifier).markRead(chat.phone);
            AppRoutes.openChat(context, chat.phone, name: chat.customerName);
          },
          child: Row(
            children: [
              _Avatar(name: chat.customerName, isUnread: isUnread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.customerName.isNotEmpty
                                ? chat.customerName
                                : chat.phone,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: KaapavTheme.gold,
                            ),
                          ),
                        if (chat.lastTimestamp != null)
                          Text(
                            _formatTime(chat.lastTimestamp!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnread
                                  ? KaapavTheme.gold
                                  : const Color(0xFF9CA3AF),
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (chat.lastDirection == 'outgoing')
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _previewText(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread
                                  ? isDark
                                      ? Colors.white70
                                      : const Color(0xFF374151)
                                  : const Color(0xFF9CA3AF),
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMuted)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(
                              Icons.notifications_off_rounded,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isMuted
                                  ? const Color(0xFF9CA3AF)
                                  : KaapavTheme.gold,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (chat.labels.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: chat.labels.take(3).map((l) {
                          final hot = l.toLowerCase().contains('hot');

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: hot
                                  ? const Color(0xFFEF4444)
                                      .withValues(alpha: 0.12)
                                  : KaapavTheme.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: hot
                                    ? const Color(0xFFEF4444)
                                        .withValues(alpha: 0.20)
                                    : KaapavTheme.gold.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              hot ? '🔥 $l' : l,
                              style: TextStyle(
                                fontSize: 10,
                                color: hot
                                    ? const Color(0xFFEF4444)
                                    : KaapavTheme.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _previewText() {
    if (chat.lastMessage?.isNotEmpty == true) return chat.lastMessage!;

    switch (chat.lastMessageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎵 Audio';
      case 'document':
        return '📄 Document';
      default:
        return 'Tap to open chat';
    }
  }

  String _formatTime(String ts) {
    try {
      return timeago.format(DateTime.parse(ts).toLocal(), locale: 'en_short');
    } catch (_) {
      return '';
    }
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isUnread;

  const _Avatar({
    required this.name,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUnread
            ? KaapavTheme.luxeGoldGradient
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  KaapavTheme.amethyst.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.20),
                ],
              ),
        border: Border.all(
          color: isUnread
              ? KaapavTheme.goldLight.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: (isUnread ? KaapavTheme.gold : KaapavTheme.amethyst)
                .withValues(alpha: isUnread ? 0.30 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: isUnread ? KaapavTheme.bgDeep : KaapavTheme.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasQuery;

  const _EmptyView({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KaapavGlassCard(
          isDark: isDark,
          radius: 24,
          padding: const EdgeInsets.all(24),
          accentColor: hasQuery ? KaapavTheme.sapphire : KaapavTheme.gold,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 58,
                color: hasQuery ? KaapavTheme.sapphire : KaapavTheme.gold,
              ),
              const SizedBox(height: 16),
              Text(
                hasQuery ? 'No chats found' : 'No chats yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: KaapavTheme.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasQuery
                    ? 'Try customer name, phone, or message keyword.'
                    : 'WhatsApp conversations will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KaapavTheme.grayLight.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KaapavGlassCard(
          isDark: isDark,
          radius: 24,
          padding: const EdgeInsets.all(24),
          accentColor: KaapavTheme.ruby,
          borderColor: KaapavTheme.ruby.withValues(alpha: 0.25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 58,
                color: KaapavTheme.ruby,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load chats',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KaapavTheme.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Check API/network and retry.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KaapavTheme.grayLight.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}