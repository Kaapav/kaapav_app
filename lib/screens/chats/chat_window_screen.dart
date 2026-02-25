// lib/screens/chats/chat_window_screen.dart
// ═══════════════════════════════════════════════════════════════
// CHAT WINDOW SCREEN — Full chat with polling
// Aligned with: Providers, Message model, KaapavTheme
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/media_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';

class ChatWindowScreen extends ConsumerStatefulWidget {
  final String phone;

  const ChatWindowScreen({
    super.key,
    required this.phone,
  });

  @override
  ConsumerState<ChatWindowScreen> createState() => _ChatWindowScreenState();
}

class _ChatWindowScreenState extends ConsumerState<ChatWindowScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatInputState> _inputKey = GlobalKey();
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set current chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).setCurrentChat(widget.phone);
      ref.read(chatProvider.notifier).markAsRead(widget.phone);

      // Fetch messages
      ref.read(messageProvider.notifier).fetchMessages(widget.phone);

      // Start polling
      ref.read(messageProvider.notifier).startPolling(
        widget.phone,
        interval: const Duration(seconds: 2),
      );
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    try {
      ref.read(messageProvider.notifier).stopPolling();
      ref.read(chatProvider.notifier).clearCurrentChat();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(messageProvider.notifier).startPolling(widget.phone);
    } else if (state == AppLifecycleState.paused) {
      ref.read(messageProvider.notifier).stopPolling();
    }
  }

  void _onScroll() {
    final atBottom = _scrollController.position.pixels <= 100;
  if (atBottom != _isAtBottom) {
    setState(() => _isAtBottom = atBottom);
  }
}

  void _scrollToBottom({bool animated = true}) {
  if (!_scrollController.hasClients) return;
  if (animated) {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  } else {
    _scrollController.jumpTo(0);
  }
}

  Future<void> _handleSend(String text) async {
    final success = await ref.read(messageProvider.notifier).sendText(
      widget.phone,
      text,
    );

    if (success) {
      _scrollToBottom();
    }
  }

  Future<void> _handleCamera() async {
  final image = await MediaService.takePhoto();
  if (image == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera cancelled or permission denied')),
    );
    return;
  }

  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Upload to R2 and get URL
    final url = await MediaService.uploadFile(image, type: 'image', phone: widget.phone);
    
    Navigator.pop(context); // Close loading

    if (url != null) {
      // Send image message with R2 URL
      final success = await ref.read(messageProvider.notifier).sendImage(widget.phone, url);
      if (success) {
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send image')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed')),
      );
    }
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttachOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _handleGallery();
                },
              ),
              _AttachOption(
                icon: Icons.insert_drive_file,
                label: 'Document',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _handleDocument();
                },
              ),
              _AttachOption(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _handleVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGallery() async {
    final image = await MediaService.pickFromGallery();
    if (image == null) return;
    await _uploadAndSend(image, 'image');
  }

  Future<void> _handleDocument() async {
    final doc = await MediaService.pickDocument();
    if (doc == null) return;
    await _uploadAndSend(doc, 'document');
  }

  Future<void> _handleVideo() async {
    final video = await MediaService.pickVideo();
    if (video == null) return;
    await _uploadAndSend(video, 'video');
  }

  Future<void> _uploadAndSend(File file, String type) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Upload to R2
    final url = await MediaService.uploadFile(file, type: type, phone: widget.phone);
    Navigator.pop(context);

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed')),
      );
      return;
    }

    // Send message with R2 URL
    bool success = false;
    if (type == 'image') {
      success = await ref.read(messageProvider.notifier).sendImage(widget.phone, url);
    } else if (type == 'document') {
      success = await ref.read(messageProvider.notifier).sendDocument(
        widget.phone,
        url,
        filename: file.path.split('/').last,
      );
    } else if (type == 'video') {
      // For video, send as document for now (WhatsApp API handles it)
      success = await ref.read(messageProvider.notifier).sendDocument(
        widget.phone,
        url,
        filename: file.path.split('/').last,
      );
    }

    if (success) {
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send')),
      );
    }
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}


  Future<void> _handleRetry(Message message) async {
    await ref.read(messageProvider.notifier).retryMessage(
      widget.phone,
      message.messageId,
    );
  }

  void _handleButtonClick(String buttonId, String buttonTitle) {
    _handleSend(buttonTitle);
  }

  void _showMessageOptions(Message message) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KaapavTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (message.text != null && message.text!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy, color: KaapavTheme.gold),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text!));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            if (message.isFailed)
              ListTile(
                leading: const Icon(Icons.refresh, color: KaapavTheme.warning),
                title: const Text('Retry'),
                onTap: () {
                  Navigator.pop(context);
                  _handleRetry(message);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(currentChatProvider);
    final customer = ref.watch(currentCustomerProvider);
    final messages = ref.watch(messagesForPhoneProvider(widget.phone));
    final messageState = ref.watch(messageProvider);
    final isLoading = messageState.isLoading(widget.phone);
    final isSending = messageState.isSending;

    ref.listen<List<Message>>(
      messagesForPhoneProvider(widget.phone),
      (previous, next) {
        if (previous != null && next.length > previous.length && _isAtBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFfafad2),
      appBar: _buildAppBar(chat, customer),
      body: Column(
        children: [
          Expanded(
            child: isLoading && messages.isEmpty
                ? _buildLoadingState()
                : messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(messages),
          ),
          ChatInput(
            key: _inputKey,
            onSend: _handleSend,
            isSending: isSending,
            onAttachment: (path, type) => _uploadAndSend(File(path), type),
            onCameraPressed: _handleCamera,
          ),
        ],
      ),
      floatingActionButton: !_isAtBottom
    ? Padding(
        padding: const EdgeInsets.only(bottom: 70), // above input bar
        child: FloatingActionButton.small(
          onPressed: () => _scrollToBottom(),
          backgroundColor: KaapavTheme.white,
          elevation: 4,
          child: const Icon(Icons.keyboard_arrow_down, color: KaapavTheme.gold),
        ),
      )
    : null,
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
);
  }

  PreferredSizeWidget _buildAppBar(chat, customer) {
    final name = chat?.customerName ?? customer?.name ?? widget.phone;
    final isTyping = ref.watch(chatProvider).typingStatus[widget.phone] ?? false;
    final onlineStatus = ref.watch(chatProvider).onlineStatus[widget.phone];

    return AppBar(
      backgroundColor: KaapavTheme.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: () {},
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: KaapavTheme.gold,
              child: Text(
                _getInitials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: KaapavTheme.dark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (customer?.tier == 'vip') ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.workspace_premium,
                          size: 14,
                          color: Color(0xFFFFD700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (isTyping)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: KaapavTheme.gold,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      onlineStatus == 'online'
                          ? 'Online'
                          : customer?.lastSeen != null
                              ? 'Last seen ${Formatters.time(Formatters.parseDate(customer!.lastSeen))}'
                              : widget.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KaapavTheme.gray,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (chat != null)
          IconButton(
            icon: Icon(
              chat.isBotEnabled ? Icons.smart_toy : Icons.smart_toy_outlined,
              color: chat.isBotEnabled ? KaapavTheme.gold : KaapavTheme.grayLight,
            ),
            tooltip: chat.isBotEnabled ? 'Bot enabled' : 'Bot disabled',
            onPressed: () {
              ref.read(chatProvider.notifier).toggleBot(widget.phone);
            },
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'star':
                ref.read(chatProvider.notifier).toggleStar(widget.phone);
                break;
              case 'refresh':
                ref.read(messageProvider.notifier).fetchMessages(widget.phone, refresh: true);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'star',
              child: Row(
                children: [
                  Icon(
                    chat?.isStarred == true ? Icons.star : Icons.star_border,
                    color: chat?.isStarred == true ? KaapavTheme.gold : null,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(chat?.isStarred == true ? 'Unstar' : 'Star'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(KaapavTheme.gold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KaapavTheme.dark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to start the conversation',
            style: TextStyle(color: KaapavTheme.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    final grouped = _groupMessagesByDate(messages);
    final entries = grouped.entries.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final dateStr = entry.key;
        final dateMessages = entry.value;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KaapavTheme.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _formatDateHeader(dateStr),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: KaapavTheme.gray,
                  ),
                ),
              ),
            ),
            ...dateMessages.map((message) => ChatBubble(
              message: message,
              onButtonClick: _handleButtonClick,
              onRetry: _handleRetry,
              onLongPress: _showMessageOptions,
            )),
          ],
        );
      },
    );
  }

  Map<String, List<Message>> _groupMessagesByDate(List<Message> messages) {
  final grouped = <String, List<Message>>{};

  for (final message in messages) {
    final dt = Formatters.parseDate(message.timestamp);
    final dateKey = dt != null
        ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
        : 'Unknown';

    grouped.putIfAbsent(dateKey, () => []);
    grouped[dateKey]!.add(message);
  }

  // ✅ Sort messages within each group by parsed DateTime (not raw string)
  grouped.forEach((key, value) {
    value.sort((a, b) {
      final aTime = Formatters.parseDate(a.timestamp);
      final bTime = Formatters.parseDate(b.timestamp);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return aTime.compareTo(bTime); // oldest → newest (top → bottom)
    });
  });

  // ✅ Sort groups newest-first (because ListView is reverse:true)
  final sorted = Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
  );

  return sorted;
}

  String _formatDateHeader(String dateStr) {
    if (dateStr == 'Unknown') return dateStr;

    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final messageDate = DateTime(dt.year, dt.month, dt.day);

      if (messageDate == today) return 'Today';
      if (messageDate == yesterday) return 'Yesterday';
      return Formatters.date(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}