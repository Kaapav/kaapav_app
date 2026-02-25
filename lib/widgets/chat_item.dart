import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/chat.dart';

class ChatItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatItem({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread
              ? (isDark
                  ? KaapavTheme.gold.withOpacity(0.05)
                  : const Color(0xFFFBF8F1))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE5E7EB),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // ── Avatar ──
            _buildAvatar(isDark),
            const SizedBox(width: 12),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Time row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (chat.isStarred)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: KaapavTheme.gold,
                                ),
                              ),
                            Flexible(
                              child: Text(
                                chat.customerName.isNotEmpty
                                    ? chat.customerName
                                    : chat.phone,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chat.lastTimestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? KaapavTheme.gold
                              : const Color(0xFF9CA3AF),
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Last message + Badge row
                  Row(
                    children: [
                      // Direction indicator + message
                      if (chat.lastDirection == 'outgoing')
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: _buildStatusIcon(),
                        ),
                      Expanded(
                        child: Text(
                          _getPreviewText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? (isDark ? Colors.white70 : const Color(0xFF374151))
                                : const Color(0xFF9CA3AF),
                            fontWeight:
                                hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Unread badge
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: KaapavTheme.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],

                      // Bot/blocked indicator
                      if (chat.isBlocked)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.block, size: 16, color: Color(0xFFEF4444)),
                        ),
                      if (!chat.isBotEnabled && !chat.isBlocked)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.smart_toy_outlined,
                              size: 16, color: Colors.grey.shade400),
                        ),
                    ],
                  ),

                  // Labels
                  if (chat.labels.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: chat.labels.take(3).map((label) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: KaapavTheme.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: KaapavTheme.gold,
                              fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildAvatar(bool isDark) {
    final initial = chat.customerName.isNotEmpty
        ? chat.customerName[0].toUpperCase()
        : '#';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: KaapavTheme.goldGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: KaapavTheme.gold.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return const Icon(
      Icons.done_all,
      size: 16,
      color: Color(0xFF9CA3AF),
    );
  }

  String _getPreviewText() {
    if (chat.lastMessage == null || chat.lastMessage!.isEmpty) {
      return 'No messages yet';
    }

    switch (chat.lastMessageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎵 Audio';
      case 'document':
        return '📄 Document';
      case 'sticker':
        return '🏷️ Sticker';
      default:
        return chat.lastMessage!;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      } else {
        return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
      }
    } catch (_) {
      return '';
    }
  }
}