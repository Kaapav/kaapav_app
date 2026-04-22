// lib/screens/chats/chat_window_screen.dart
// ---------------------------------------------------------------
// CHAT WINDOW SCREEN   Full chat with polling
// Aligned with: Providers, Message model, KaapavTheme
// ---------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/media_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'media_gallery_screen.dart';
import '../../widgets/full_screen_image.dart';
import 'contact_info_screen.dart';
import 'starred_messages_screen.dart';
import '../../services/api/api_client.dart';
import '../../models/product.dart';
import '../../services/api/product_api.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';

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
  bool _isSearching = false;
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Message? _replyingTo;

  @override
  void initState() {
    super.initState();
NotificationService.activeChatPhone = widget.phone;
NotificationService.instance.cancelForPhone(widget.phone);
    WidgetsBinding.instance.addObserver(this);

    // Set current chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).setCurrentChat(widget.phone);
      ref.read(chatProvider.notifier).markAsRead(widget.phone);

      // Fetch messages
      // ❌ REMOVED:ref.read(messageProvider.notifier).fetchMessages(widget.phone);

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
NotificationService.activeChatPhone = null;
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
  if (!_scrollController.hasClients) return;
  // reverse:false → bottom = maxScrollExtent
  final atBottom = (_scrollController.position.maxScrollExtent -
      _scrollController.position.pixels) <= 150;
  if (atBottom != _isAtBottom) {
    setState(() => _isAtBottom = atBottom);
  }
}

void _scrollToBottom({bool animated = true}) {
  if (!_scrollController.hasClients) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  });
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

   Future<void> _handleVoiceSend(String path, Duration duration) async {
    final file = File(path);
    await _uploadAndSend(file, 'audio');
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

    Color _resolveWallpaperColor(bool isDark, String wallpaper) {
    switch (wallpaper) {
      case 'cream':
        return const Color(0xFFFBF8F1);
      case 'dark':
        return const Color(0xFF1A1A1A);
      case 'gold':
        return const Color(0xFFF5E6C8);
      case 'gray':
        return const Color(0xFFF0F0F0);
      case 'mint':
        return const Color(0xFFE8F5E9);
      case 'sky':
        return const Color(0xFFE3F2FD);
      case 'default':
      default:
        return isDark ? const Color(0xFF121212) : const Color(0xFFFAFAD2);
    }
  }

  bool _isReadReceiptsEnabled(Map<String, dynamic> settings) {
    final value = settings['read_receipts'];
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return true;
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
              _AttachOption(
                icon: Icons.diamond_outlined,
                label: 'Send Product',
                color: KaapavTheme.gold,
                onTap: () {
                  Navigator.pop(context);
                  _showProductPicker();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatProductPicker(
        phone: widget.phone,
        isDark: Theme.of(context).brightness == Brightness.dark,
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

    // -- SAVE TO GALLERY --
  Future<void> _handleSaveToGallery(Message message) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery permission denied')),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving...')),
      );

      final tempDir = await getTemporaryDirectory();
      final ext = message.messageType == 'video' ? 'mp4' : 'jpg';
      final filePath = '${tempDir.path}/KAAPAV_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Dio().download(message.mediaUrl!, filePath);

      if (message.messageType == 'video') {
        await Gal.putVideo(filePath, album: 'KAAPAV');
      } else {
        await Gal.putImage(filePath, album: 'KAAPAV');
      }

      try { await File(filePath).delete(); } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('? Saved to gallery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  // -- OPEN DOCUMENT --
  Future<void> _handleOpenDocument(Message message) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading...')),
      );

      final tempDir = await getTemporaryDirectory();
      final filename = message.mediaCaption ?? 'document';
      final filePath = '${tempDir.path}/$filename';
      await Dio().download(message.mediaUrl!, filePath);

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  // -- SHARE MESSAGE --
  Future<void> _handleShareMessage(Message message) async {
    try {
      if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final ext = message.messageType == 'image' ? 'jpg' : message.messageType == 'video' ? 'mp4' : 'file';
        final filePath = '${tempDir.path}/KAAPAV_share_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await Dio().download(message.mediaUrl!, filePath);
        await Share.shareXFiles([XFile(filePath)], text: message.mediaCaption ?? message.text);
      } else if (message.text != null && message.text!.isNotEmpty) {
        await Share.share(message.text!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  // -- DELETE MESSAGE (local only) --
    void _handleDelete(Message message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_outline, color: KaapavTheme.error, size: 24),
          SizedBox(width: 8),
          Text('Delete Message'),
        ]),
        content: const Text('Choose how to delete this message.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: KaapavTheme.gray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(messageProvider.notifier).deleteMessage(widget.phone, message.messageId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(children: [
                    Icon(Icons.delete, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Deleted for you'),
                  ]),
                  backgroundColor: KaapavTheme.gold,
                ),
              );
            },
            child: const Text('Delete for Me', style: TextStyle(color: KaapavTheme.error)),
          ),
          if (message.isOutgoing && _canDeleteForEveryone(message))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteForEveryone(message);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KaapavTheme.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete for Everyone',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
    );
  }


    Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final messages = ref.read(messagesForPhoneProvider(widget.phone));
    final selectedMsgs = messages.where((m) => _selectedIds.contains(m.messageId)).toList();
    final hasOutgoing = selectedMsgs.any((m) => m.isOutgoing && _canDeleteForEveryone(m));

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.delete_outline, color: KaapavTheme.error, size: 24),
          const SizedBox(width: 8),
          Text('Delete $count Message${count > 1 ? 's' : ''}'),
        ]),
        content: const Text('Choose how to delete selected messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: KaapavTheme.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'me'),
            child: const Text('Delete for Me', style: TextStyle(color: KaapavTheme.error)),
          ),
          if (hasOutgoing)
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'everyone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KaapavTheme.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete for Everyone',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
    );

    if (result == null) return;
    int deleted = 0;

    if (result == 'everyone') {
      for (final msg in selectedMsgs) {
        if (msg.isOutgoing && _canDeleteForEveryone(msg)) {
          await ref.read(messageProvider.notifier).deleteForEveryone(widget.phone, msg.messageId);
        } else {
          ref.read(messageProvider.notifier).deleteMessage(widget.phone, msg.messageId);
        }
        deleted++;
      }
    } else {
      for (final id in _selectedIds) {
        ref.read(messageProvider.notifier).deleteMessage(widget.phone, id);
        deleted++;
      }
    }

    setState(() { _isSelecting = false; _selectedIds.clear(); });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.delete, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$deleted message(s) deleted${result == 'everyone' ? ' for everyone' : ''}'),
          ]),
          backgroundColor: KaapavTheme.gold,
        ),
      );
    }
  }

  // -- EXPORT CHAT --
  Future<void> _handleExportChat() async {
    final messages = ref.read(messagesForPhoneProvider(widget.phone));
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to export')),
      );
      return;
    }

    final chat = ref.read(currentChatProvider);
    final name = chat?.customerName ?? widget.phone;
    final buffer = StringBuffer();
    buffer.writeln('KAAPAV Chat Export   $name');
    buffer.writeln('Exported: ${DateTime.now()}');
    buffer.writeln('${'-' * 40}\n');

    // Reverse because messages are sorted newest-first
    for (final msg in messages.reversed) {
      final sender = msg.isOutgoing ? 'You' : name;
      final time = msg.timestamp ?? '';
      final text = msg.text ?? msg.displayText;
      buffer.writeln('[$time] $sender: $text');
    }

    await Share.share(buffer.toString(), subject: 'Chat with $name');
  }

    void _showDisappearingOptions() {
    final currentDuration = ref.read(chatProvider).disappearingSettings[widget.phone];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: KaapavTheme.border, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [
                  Icon(Icons.timer, color: KaapavTheme.gold, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Disappearing Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('Messages will be deleted after the selected time',
                        style: TextStyle(fontSize: 12, color: KaapavTheme.gray)),
                  ])),
                ]),
              ),
              const Divider(),
              _DisappearingOption(label: 'Off', subtitle: 'Messages won\'t disappear',
                icon: Icons.timer_off_outlined, isSelected: currentDuration == null,
                onTap: () { Navigator.pop(ctx); _setDisappearing(null); }),
              _DisappearingOption(label: '24 Hours', subtitle: 'Messages disappear after 1 day',
                icon: Icons.hourglass_bottom, isSelected: currentDuration == '24h',
                onTap: () { Navigator.pop(ctx); _setDisappearing('24h'); }),
              _DisappearingOption(label: '7 Days', subtitle: 'Messages disappear after 1 week',
                icon: Icons.calendar_today, isSelected: currentDuration == '7d',
                onTap: () { Navigator.pop(ctx); _setDisappearing('7d'); }),
              _DisappearingOption(label: '90 Days', subtitle: 'Messages disappear after 3 months',
                icon: Icons.calendar_month, isSelected: currentDuration == '90d',
                onTap: () { Navigator.pop(ctx); _setDisappearing('90d'); }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _setDisappearing(String? duration) {
    ref.read(chatProvider.notifier).setDisappearing(widget.phone, duration);
    final label = duration == null ? 'off'
        : duration == '24h' ? '24 hours'
        : duration == '7d' ? '7 days' : '90 days';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(duration == null ? Icons.timer_off : Icons.timer, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Disappearing messages ${duration == null ? 'turned off' : 'set to $label'}'),
        ]),
        backgroundColor: KaapavTheme.gold,
      ),
    );
  }

  void _handleButtonClick(String buttonId, String buttonTitle) {
    _handleSend(buttonTitle);
  }
 
    void _handleEdit(Message message) {
  final controller = TextEditingController(text: message.text ?? '');

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.edit, color: KaapavTheme.gold, size: 22),
        SizedBox(width: 8),
        Text('Edit Message'),
      ]),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 5,
        minLines: 1,
        decoration: InputDecoration(
          hintText: 'Edit your message…',
          filled: true,
          fillColor: KaapavTheme.gold.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: KaapavTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: KaapavTheme.gold),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: KaapavTheme.gray)),
        ),
        ElevatedButton(
          onPressed: () {
            final newText = controller.text.trim();
            if (newText.isEmpty || newText == message.text) {
              Navigator.pop(ctx);
              return;
            }
            Navigator.pop(ctx);
            _executeEdit(message, newText);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KaapavTheme.gold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
        ),
  ).then((_) => controller.dispose());
}

Future<void> _executeEdit(Message message, String newText) async {
  ref.read(messageProvider.notifier).editMessage(
    widget.phone,
    message.messageId,
    newText,
  );

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.edit, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Message edited'),
        ]),
        backgroundColor: KaapavTheme.gold,
      ),
    );
  }
}

    /// Forward a single message (from long-press menu)
void _handleForward(Message message) {
  _showForwardPicker([message]);
}

/// Forward selected messages (from selection mode)
void _forwardSelected() {
  if (_selectedIds.isEmpty) return;
  final allMsgs = ref.read(messagesForPhoneProvider(widget.phone));
  final selected = allMsgs
      .where((m) => _selectedIds.contains(m.messageId))
      .toList()
    ..sort((a, b) => (a.timestamp ?? '').compareTo(b.timestamp ?? ''));

  _showForwardPicker(selected);
}

/// Show the chat picker sheet
void _showForwardPicker(List<Message> messages) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ForwardChatPicker(
      messages: messages,
      currentPhone: widget.phone,
      isDark: Theme.of(context).brightness == Brightness.dark,
      onForward: (targetPhones) => _executeForward(messages, targetPhones),
    ),
  );
}

/// Actually send forwarded messages
Future<void> _executeForward(
    List<Message> messages, List<String> targetPhones) async {
  Navigator.pop(context); // close picker

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white)),
        const SizedBox(width: 12),
        Text(
            'Forwarding ${messages.length} message(s) to ${targetPhones.length} chat(s)…'),
      ]),
      duration: const Duration(seconds: 10),
      backgroundColor: KaapavTheme.gold,
    ),
  );

  int successCount = 0;
  int failCount = 0;

  for (final phone in targetPhones) {
    for (final msg in messages) {
      try {
        bool sent = false;

        if (msg.messageType == 'image' &&
            msg.mediaUrl != null &&
            msg.mediaUrl!.isNotEmpty) {
          sent = await ref
              .read(messageProvider.notifier)
              .sendImage(phone, msg.mediaUrl!);
        } else if (msg.messageType == 'document' &&
            msg.mediaUrl != null &&
            msg.mediaUrl!.isNotEmpty) {
          sent = await ref.read(messageProvider.notifier).sendDocument(
                phone,
                msg.mediaUrl!,
                filename: msg.mediaCaption ?? 'document',
              );
        } else if (msg.messageType == 'video' &&
            msg.mediaUrl != null &&
            msg.mediaUrl!.isNotEmpty) {
          sent = await ref.read(messageProvider.notifier).sendDocument(
                phone,
                msg.mediaUrl!,
                filename: msg.mediaCaption ?? 'video.mp4',
              );
        } else {
          final forwardText = msg.text ?? msg.displayText;
          if (forwardText.isNotEmpty) {
            sent = await ref
                .read(messageProvider.notifier)
                .sendText(phone, forwardText);
          }
        }

        if (sent) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }
  }

  setState(() {
    _isSelecting = false;
    _selectedIds.clear();
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        Icon(
          failCount == 0 ? Icons.check_circle : Icons.warning_amber,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(failCount == 0
            ? '✅ Forwarded $successCount message(s)'
            : '⚠️ $successCount sent, $failCount failed'),
      ]),
      backgroundColor:
          failCount == 0 ? const Color(0xFF10B981) : KaapavTheme.warning,
    ),
  );
}

    void _showMessageOptions(Message message) {
    HapticFeedback.mediumImpact();
    final hasMedia = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;
    final hasText = message.text != null && message.text!.isNotEmpty;
    final isImage = message.messageType == 'image' && hasMedia;
    final isDoc = message.messageType == 'document' && hasMedia;
    final isVideo = message.messageType == 'video' && hasMedia;

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
              width: 40, height: 4,
              decoration: BoxDecoration(color: KaapavTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),

            // -- Reply --
            ListTile(
              leading: const Icon(Icons.reply, color: KaapavTheme.gold),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = message);
              },
            ),

            // -- Copy (text only) --
            if (hasText)
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

            // -- Save to Gallery (image/video) --
            if (isImage || isVideo)
              ListTile(
                leading: const Icon(Icons.download, color: KaapavTheme.gold),
                title: const Text('Save to Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _handleSaveToGallery(message);
                },
              ),

            // -- Open Document --
            if (isDoc)
              ListTile(
                leading: const Icon(Icons.open_in_new, color: KaapavTheme.gold),
                title: const Text('Open Document'),
                onTap: () {
                  Navigator.pop(context);
                  _handleOpenDocument(message);
                },
              ),

            // -- View Fullscreen (image) --
            if (isImage)
              ListTile(
                leading: const Icon(Icons.zoom_in, color: KaapavTheme.gold),
                title: const Text('View Full Screen'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FullScreenImage(
                      imageUrl: message.mediaUrl!,
                      caption: message.mediaCaption,
                      timestamp: message.timestamp,
                    ),
                  ));
                },
              ),

            // -- Play Video --
            if (isVideo)
              ListTile(
                leading: const Icon(Icons.play_arrow, color: KaapavTheme.gold),
                title: const Text('Play Video'),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse(message.mediaUrl!), mode: LaunchMode.externalApplication);
                },
              ),

            // -- Share --
            ListTile(
              leading: const Icon(Icons.share, color: KaapavTheme.gold),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _handleShareMessage(message);
              },
            ),
          // -- Forward --
          ListTile(
            leading: const Icon(Icons.forward, color: KaapavTheme.gold),
            title: const Text('Forward'),
            onTap: () {
              Navigator.pop(context);
              _handleForward(message);
            },
          ),

          // -- Edit (outgoing text only, within 15 min) --
          if (message.isOutgoing &&
              message.messageType == 'text' &&
              message.text != null &&
              !message.isFailed &&
              _canEdit(message))
            ListTile(
              leading: const Icon(Icons.edit, color: KaapavTheme.gold),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _handleEdit(message);
              },
            ),
            // -- Delete --
            ListTile(
              leading: const Icon(Icons.delete_outline, color: KaapavTheme.error),
              title: const Text('Delete', style: TextStyle(color: KaapavTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _handleDelete(message);
              },
            ),

	     // -- Select --
ListTile(
  leading: const Icon(Icons.check_circle_outline, color: KaapavTheme.gold),
  title: const Text('Select'),
  onTap: () {
    Navigator.pop(context);
    setState(() {
      _isSelecting = true;
      _selectedIds.add(message.messageId);
    });
  },
),	
            
            // -- Retry (failed only) --
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
    final settings = ref.watch(settingsProvider).settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallpaper = (settings['chat_wallpaper'] ?? 'default').toString();
    final readReceiptsEnabled = _isReadReceiptsEnabled(settings);
    final wallpaperColor = _resolveWallpaperColor(isDark, wallpaper);
    final isLoading = messageState.isLoading(widget.phone);
    final isSending = messageState.isSending;

   // In build() method, replace the existing ref.listen:
ref.listen<List<Message>>(
  messagesForPhoneProvider(widget.phone),
  (previous, next) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      
      if (previous == null || previous.isEmpty) {
        // First load - jump to bottom instantly
        _scrollToBottom(animated: false);
      } else if (next.length > previous.length && _isAtBottom) {
        // New message arrived and user is at bottom
        _scrollToBottom();
      }
    });
  },
);

    return Scaffold(
      backgroundColor: wallpaperColor,
      appBar: _buildAppBar(chat, customer),
              body: Column(
          children: [
            Expanded(
              child: Container(
                color: wallpaperColor,
                child: isLoading && messages.isEmpty
                    ? _buildLoadingState()
                    : messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(messages, readReceiptsEnabled),
              ),
            ),

            // -- Reply Preview Bar (NEW) --
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  border: const Border(top: BorderSide(color: KaapavTheme.border)),
                  ),
                child: Row(
                  children: [
                    Container(width: 4, height: 40, decoration: BoxDecoration(
                      color: KaapavTheme.gold, borderRadius: BorderRadius.circular(2),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _replyingTo!.isOutgoing ? 'You' : (ref.read(currentChatProvider)?.customerName ?? widget.phone),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KaapavTheme.gold),
                          ),
                          Text(
                            _replyingTo!.displayText,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: KaapavTheme.gray),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: KaapavTheme.gray),
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),

          ChatInput(
            key: _inputKey,
            onSend: _handleSend,
            isSending: isSending,
	    onAttachPressed: _showAttachmentPicker,
            onAttachment: (path, type) => _uploadAndSend(File(path), type),
            onCameraPressed: _handleCamera,
            onVoiceCompleted: _handleVoiceSend,
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

    // Selection mode AppBar
    if (_isSelecting) {
  final allMessages = ref.read(messagesForPhoneProvider(widget.phone));
  final allSelected = _selectedIds.length == allMessages.length && allMessages.isNotEmpty;

  return AppBar(
    backgroundColor: KaapavTheme.dark,
    leading: IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () => setState(() { _isSelecting = false; _selectedIds.clear(); }),
    ),
    title: Text(
      '${_selectedIds.length} selected',
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    actions: [
      IconButton(
        icon: Icon(allSelected ? Icons.deselect : Icons.select_all, color: Colors.white),
        tooltip: allSelected ? 'Deselect All' : 'Select All',
        onPressed: () {
          setState(() {
            if (allSelected) {
              _selectedIds.clear();
              _isSelecting = false;
            } else {
              _selectedIds.addAll(allMessages.map((m) => m.messageId));
            }
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.copy, color: Colors.white),
        tooltip: 'Copy',
        onPressed: () {
          final msgs = ref.read(messagesForPhoneProvider(widget.phone));
          final selected = msgs
              .where((m) => _selectedIds.contains(m.messageId))
              .toList()
            ..sort((a, b) => (a.timestamp ?? '').compareTo(b.timestamp ?? ''));
          final text = selected.map((m) {
            final dir = m.isOutgoing ? 'You' : (ref.read(currentChatProvider)?.customerName ?? widget.phone);
            return '[$dir] ${m.displayText}';
          }).join('\n\n');
          Clipboard.setData(ClipboardData(text: text));
          setState(() { _isSelecting = false; _selectedIds.clear(); });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(children: [
                Icon(Icons.copy, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Messages copied'),
              ]),
              backgroundColor: KaapavTheme.gold,
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.bookmark_outline, color: Colors.white),
        tooltip: 'Save',
        onPressed: () {
          for (final id in _selectedIds) {
            ref.read(messageProvider.notifier).starMessage(widget.phone, id);
          }
          final count = _selectedIds.length;
          setState(() { _isSelecting = false; _selectedIds.clear(); });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.bookmark, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('$count message(s) saved'),
              ]),
              backgroundColor: KaapavTheme.gold,
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.share, color: Colors.white),
        tooltip: 'Share',
        onPressed: () {
          final msgs = ref.read(messagesForPhoneProvider(widget.phone));
          final selected = msgs
              .where((m) => _selectedIds.contains(m.messageId))
              .toList()
            ..sort((a, b) => (a.timestamp ?? '').compareTo(b.timestamp ?? ''));
          final text = selected.map((m) => m.displayText).join('\n\n');
          Share.share(text);
          setState(() { _isSelecting = false; _selectedIds.clear(); });
        },
      ),
      IconButton(
        icon: const Icon(Icons.forward, color: Colors.white),
        tooltip: 'Forward',
        onPressed: () => _forwardSelected(),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
        tooltip: 'Delete',
        onPressed: () => _deleteSelected(),
      ),
    ],
  );
}

    // Search mode AppBar
    if (_isSearching) {
      return AppBar(
        backgroundColor: KaapavTheme.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() { _isSearching = false; _searchQuery = ''; _searchController.clear(); })),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search messages...', border: InputBorder.none),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(icon: const Icon(Icons.close),
              onPressed: () => setState(() { _searchQuery = ''; _searchController.clear(); })),
        ],
      );
    }

    // Normal AppBar
    return AppBar(
      backgroundColor: KaapavTheme.white, elevation: 0, scrolledUnderElevation: 1,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      titleSpacing: 0,
      title: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ContactInfoScreen(phone: widget.phone))),
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: KaapavTheme.gold,
            child: Text(_getInitials(name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: KaapavTheme.dark),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (customer?.tier == 'vip') ...[
                const SizedBox(width: 4), const Icon(Icons.workspace_premium, size: 14, color: Color(0xFFFFD700))],
            ]),
            const SizedBox(height: 2),
            if (isTyping)
              const Text('typing...', style: TextStyle(fontSize: 12, color: KaapavTheme.gold, fontStyle: FontStyle.italic))
            else
              Text(onlineStatus == 'online' ? 'Online'
                  : customer?.lastSeen != null ? 'Last seen ${Formatters.time(Formatters.parseDate(customer!.lastSeen))}' : widget.phone,
                style: const TextStyle(fontSize: 12, color: KaapavTheme.gray)),
          ])),
        ]),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search, color: KaapavTheme.gray), tooltip: 'Search',
          onPressed: () => setState(() => _isSearching = true)),
        IconButton(
          icon: const Icon(Icons.photo_library_outlined, color: KaapavTheme.gray), tooltip: 'Media',
          onPressed: () {
            final messages = ref.read(messagesForPhoneProvider(widget.phone));
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => MediaGalleryScreen(messages: messages, chatName: name)));
          },
        ),
        if (chat != null)
          IconButton(
            icon: Icon(chat.isBotEnabled ? Icons.smart_toy : Icons.smart_toy_outlined,
                color: chat.isBotEnabled ? KaapavTheme.gold : KaapavTheme.grayLight),
            tooltip: chat.isBotEnabled ? 'Bot enabled' : 'Bot disabled',
            onPressed: () => ref.read(chatProvider.notifier).toggleBot(widget.phone),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
            switch (value) {
              case 'star': ref.read(chatProvider.notifier).toggleStar(widget.phone); break;
              case 'refresh': ref.read(messageProvider.notifier).fetchMessages(widget.phone, refresh: true); break;
              case 'export': _handleExportChat(); break;
              case 'select': setState(() => _isSelecting = true); break;
              case 'starred': Navigator.push(context, MaterialPageRoute(builder: (_) => const StarredMessagesScreen())); break;
              case 'mute':
                ref.read(chatProvider.notifier).toggleMute(widget.phone);
                final isMuted = ref.read(chatProvider).mutedChats.contains(widget.phone);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      Icon(isMuted ? Icons.notifications_off : Icons.notifications_active, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(isMuted ? 'Notifications muted' : 'Notifications unmuted'),
                    ]),
                    backgroundColor: KaapavTheme.gold,
                  ));
                }
                break;
              case 'pin':
                ref.read(chatProvider.notifier).togglePin(widget.phone);
                final isPinned = ref.read(chatProvider).pinnedChats.contains(widget.phone);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(isPinned ? 'Chat pinned' : 'Chat unpinned'),
                    ]),
                    backgroundColor: KaapavTheme.gold,
                  ));
                }
                break;
                        case 'block':
                final isBlocked = ref.read(currentChatProvider)?.isBlocked ?? false;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(children: [
                      Icon(isBlocked ? Icons.check_circle_outline : Icons.block,
                          color: isBlocked ? KaapavTheme.gold : KaapavTheme.error, size: 24),
                      const SizedBox(width: 8),
                      Text(isBlocked ? 'Unblock Contact?' : 'Block Contact?'),
                    ]),
                    content: Text(isBlocked
                        ? 'You will start receiving messages again.'
                        : 'Blocked contacts cannot send you messages.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(color: KaapavTheme.gray))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBlocked ? KaapavTheme.gold : KaapavTheme.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isBlocked ? 'Unblock' : 'Block',
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(chatProvider.notifier).toggleBlock(widget.phone);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [
                        Icon(isBlocked ? Icons.check_circle : Icons.block, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(isBlocked ? 'Contact unblocked' : 'Contact blocked'),
                      ]),
                      backgroundColor: isBlocked ? KaapavTheme.gold : KaapavTheme.error,
                    ));
                  }
                }
                break;
              case 'disappearing':
                _showDisappearingOptions();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'star', child: Row(children: [
              Icon(chat?.isStarred == true ? Icons.star : Icons.star_border,
                  color: chat?.isStarred == true ? KaapavTheme.gold : null, size: 20),
              const SizedBox(width: 12), Text(chat?.isStarred == true ? 'Unstar' : 'Star')])),
            const PopupMenuItem(value: 'select', child: Row(children: [Icon(Icons.check_circle_outline, size: 20), SizedBox(width: 12), Text('Select Messages')])),
            const PopupMenuItem(value: 'starred', child: Row(children: [Icon(Icons.star, size: 20), SizedBox(width: 12), Text('Starred Messages')])),
            const PopupMenuItem(value: 'refresh', child: Row(children: [Icon(Icons.refresh, size: 20), SizedBox(width: 12), Text('Refresh')])),
            const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.upload_file, size: 20), SizedBox(width: 12), Text('Export Chat')])),
            PopupMenuItem(
              value: 'mute',
              child: Row(children: [
                Icon(
                  ref.read(chatProvider).mutedChats.contains(widget.phone)
                      ? Icons.notifications_active : Icons.notifications_off_outlined,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(ref.read(chatProvider).mutedChats.contains(widget.phone)
                    ? 'Unmute Notifications' : 'Mute Notifications'),
              ]),
            ),
            PopupMenuItem(
              value: 'pin',
              child: Row(children: [
                Icon(
                  ref.read(chatProvider).pinnedChats.contains(widget.phone)
                      ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(ref.read(chatProvider).pinnedChats.contains(widget.phone)
                    ? 'Unpin Chat' : 'Pin Chat'),
              ]),
            ),
            PopupMenuItem(value: 'disappearing', child: Row(children: [
              Icon(Icons.timer_outlined, size: 20,
                  color: ref.read(chatProvider).disappearingSettings[widget.phone] != null ? KaapavTheme.gold : null),
              const SizedBox(width: 12),
              Text(ref.read(chatProvider).disappearingSettings[widget.phone] != null
                  ? 'Disappearing: ON' : 'Disappearing Messages'),
            ])),
            PopupMenuItem(
              value: 'block',
              child: Row(children: [
                Icon(Icons.block, size: 20, color: chat?.isBlocked == true ? KaapavTheme.gold : KaapavTheme.error),
                const SizedBox(width: 12),
                Text(chat?.isBlocked == true ? 'Unblock Contact' : 'Block Contact',
                    style: TextStyle(color: chat?.isBlocked == true ? KaapavTheme.gold : KaapavTheme.error)),
              ]),
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

  Widget _buildMessagesList(List<Message> messages, bool readReceiptsEnabled) {
  var filtered = messages;
  if (_searchQuery.isNotEmpty) {
    filtered = messages.where((m) =>
      (m.text ?? '').toLowerCase().contains(_searchQuery) ||
      (m.mediaCaption ?? '').toLowerCase().contains(_searchQuery)
    ).toList();
  }

  final grouped = _groupMessagesByDate(filtered);
  final entries = grouped.entries.toList(); // oldest date first

  return ListView.builder(
    controller: _scrollController,
    reverse: false, // oldest at top, newest at bottom
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      final dateStr = entry.key;
      final dateMessages = entry.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Date Header ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatDateHeader(dateStr),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // ── Messages ──
          ...dateMessages.map((message) {
            final isSelected = _selectedIds.contains(message.messageId);
            final isOutgoing = message.isOutgoing;

            final bubbleMessage = !readReceiptsEnabled && isOutgoing
                ? message.copyWith(
                    status: message.isFailed ? 'failed' : 'sent',
                    readAt: null,
                    deliveredAt: null,
                  )
                : message;

            Widget bubble = ChatBubble(
              message: bubbleMessage,
              onButtonClick: _handleButtonClick,
              onRetry: _handleRetry,
              onLongPress: _isSelecting
                  ? (_) => setState(() {
                      if (isSelected) {
                        _selectedIds.remove(message.messageId);
                      } else {
                        _selectedIds.add(message.messageId);
                      }
                    })
                  : _showMessageOptions,
            );

            // ── Selection Mode Wrapper ──
            if (_isSelecting) {
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedIds.remove(message.messageId);
                  } else {
                    _selectedIds.add(message.messageId);
                  }
                }),
                child: Container(
                  color: isSelected
                      ? KaapavTheme.gold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected
                              ? KaapavTheme.gold
                              : KaapavTheme.grayLight,
                          size: 22,
                        ),
                      ),
                      Expanded(child: bubble),
                    ],
                  ),
                ),
              );
            }

            // ── Swipe to Reply ──
            return Dismissible(
              key: Key('swipe_${message.messageId}'),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (_) async {
                HapticFeedback.lightImpact();
                setState(() => _replyingTo = message);
                return false;
              },
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                child: const Icon(Icons.reply,
                    color: KaapavTheme.gold, size: 28),
              ),
              child: bubble,
            );
          }),
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

  // Sort messages within each group: oldest → newest
  grouped.forEach((key, value) {
    value.sort((a, b) {
      final aTime = Formatters.parseDate(a.timestamp);
      final bTime = Formatters.parseDate(b.timestamp);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return aTime.compareTo(bTime);
    });
  });

  // Sort date groups: oldest → newest (ascending)
  final sorted = Map.fromEntries(
    grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)), // ✅ ascending
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

    bool _canDeleteForEveryone(Message message) {
    if (message.timestamp == null) return false;
    final sentTime = Formatters.parseDate(message.timestamp);
    if (sentTime == null) return false;
    return DateTime.now().difference(sentTime).inHours < 1;
  }

  Future<void> _deleteForEveryone(Message message) async {
    final success = await ref.read(messageProvider.notifier).deleteForEveryone(
      widget.phone, message.messageId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(success ? 'Deleted for everyone' : 'Failed to delete'),
          ]),
          backgroundColor: success ? const Color(0xFF10B981) : KaapavTheme.error,
        ),
      );
    }
  }

  bool _canEdit(Message message) {
  if (message.timestamp == null) return false;
  final sentTime = Formatters.parseDate(message.timestamp);
  if (sentTime == null) return false;
  final diff = DateTime.now().difference(sentTime);
  return diff.inMinutes <= 15; // WhatsApp allows ~15 min edit window
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
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}


class _DisappearingOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DisappearingOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: isSelected ? KaapavTheme.gold : KaapavTheme.gold.withValues(alpha: 0.1),
        child: Icon(icon, color: isSelected ? Colors.white : KaapavTheme.gold, size: 20),
      ),
      title: Text(label, style: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? KaapavTheme.gold : null,
      )),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: KaapavTheme.gray)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: KaapavTheme.gold, size: 22) : null,
      onTap: onTap,
    );
  }
}
class _ChatProductPicker extends StatefulWidget {
  final String phone;
  final bool isDark;
  const _ChatProductPicker({required this.phone, required this.isDark});

  @override
  State<_ChatProductPicker> createState() => _ChatProductPickerState();
}

class _ChatProductPickerState extends State<_ChatProductPicker> {
  final _searchCtrl = TextEditingController();
  final _productApi = ProductApi();
  List<Product> _all = [];
  List<Product> _filtered = [];
  String _cat = 'all';
  bool _loading = true;
  String? _sending;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => _filter());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final res = await _productApi.getProducts(limit: 500);
      final raw = res.data is List ? res.data : (res.data['products'] ?? []);
      final products = (raw as List).map((j) => Product.fromJson(j)).toList();
      products.sort((a, b) => a.name.compareTo(b.name));
      setState(() { _all = products; _filtered = products; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        final catOk = _cat == 'all' || p.category == _cat;
        final searchOk = q.isEmpty || p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
        return catOk && searchOk;
      }).toList();
    });
  }

  void _selectCat(String cat) { setState(() => _cat = cat); _filter(); }

  Future<void> _send(Product p) async {
  setState(() => _sending = p.sku);
  try {
    await ApiClient.instance.post(
      '/api/products/send',
      data: {'sku': p.sku, 'phone': widget.phone},
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Sent ${p.name}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    setState(() => _sending = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

   @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F0C07) : Colors.white;
    final border = widget.isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);
    final cats = ['all', ..._all.map((p) => p.category ?? '').where((c) => c.isNotEmpty).toSet().toList()..sort()];

    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: KaapavTheme.gold))),
        child: Column(children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Text('Send Product', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          // Search
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 13, color: widget.isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                filled: true, fillColor: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KaapavTheme.gold)),
              ),
            ),
          ),
          // Category tabs
          SizedBox(height: 36, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final c = cats[i];
              final isOn = c == _cat;
              final label = c == 'all' ? 'All' : c[0].toUpperCase() + c.substring(1);
              return GestureDetector(
                onTap: () => _selectCat(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOn ? KaapavTheme.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isOn ? KaapavTheme.gold : border),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 11,
                      fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
                      color: isOn ? Colors.white : const Color(0xFF9CA3AF))),
                ),
              );
            },
          )),
          const SizedBox(height: 8),
          // Products list
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No products found'))
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        final isSending = _sending == p.sku;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: Row(children: [
                            // Thumb
                            Container(width: 44, height: 44,
                              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: border)),
                              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                  ? ClipRRect(borderRadius: BorderRadius.circular(7),
                                      child: Image.network(p.imageUrl!, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(child: Text('💎'))))
                                  : const Center(child: Text('💎', style: TextStyle(fontSize: 20))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                      color: widget.isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A))),
                              const SizedBox(height: 2),
                              Text('₹${p.price.toStringAsFixed(0)} · ${p.stock} in stock',
                                  style: TextStyle(fontSize: 11, color: KaapavTheme.gold)),
                            ])),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: isSending ? null : () => _send(p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSending ? const Color(0xFF9CA3AF) : KaapavTheme.gold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isSending
                                    ? const SizedBox(width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Send', style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ]),
                        );
                      },
                    )),
        ]),
      ),
    );
  }
}

 // ═══════════════════════════════════════════════════════════════
// 🟢 ForwardChatPicker
// ═══════════════════════════════════════════════════════════════

class _ForwardChatPicker extends ConsumerStatefulWidget {
  final List<Message> messages;
  final String currentPhone;
  final bool isDark;
  final void Function(List<String> targetPhones) onForward;

  const _ForwardChatPicker({
    required this.messages,
    required this.currentPhone,
    required this.isDark,
    required this.onForward,
  });

  @override
  ConsumerState<_ForwardChatPicker> createState() => _ForwardChatPickerState();
}

class _ForwardChatPickerState extends ConsumerState<_ForwardChatPicker> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final allChats = chatState.chats
        .where((c) => c.phone != widget.currentPhone)
        .toList();

    final filtered = _query.isEmpty
        ? allChats
        : allChats.where((c) {
            return c.customerName.toLowerCase().contains(_query) ||
                c.phone.toLowerCase().contains(_query);
          }).toList();

    final bg = widget.isDark ? const Color(0xFF0F0C07) : Colors.white;
    final border =
        widget.isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);
    final msgCount = widget.messages.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: KaapavTheme.gold)),
        ),
        child: Column(
          children: [
            // ── Handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.forward,
                      color: KaapavTheme.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Forward to…',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$msgCount message${msgCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: KaapavTheme.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDark
                      ? const Color(0xFFF2E8D0)
                      : const Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search chats…',
                  hintStyle: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: widget.isDark
                      ? const Color(0xFF1A1208)
                      : const Color(0xFFF9F6EF),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: KaapavTheme.gold),
                  ),
                ),
              ),
            ),

            // ── Selected chips ──
            if (_selected.isNotEmpty)
              Container(
                height: 42,
                padding: const EdgeInsets.only(bottom: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _selected.map((phone) {
                    final chat = allChats
                        .where((c) => c.phone == phone)
                        .firstOrNull;
                    final name = chat?.customerName ?? phone;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(name,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                        backgroundColor: KaapavTheme.gold,
                        deleteIconColor: Colors.white,
                        onDeleted: () =>
                            setState(() => _selected.remove(phone)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.only(left: 8, right: 2),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const Divider(height: 1),

            // ── Chat list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: border),
                          const SizedBox(height: 8),
                          const Text('No chats found',
                              style:
                                  TextStyle(color: KaapavTheme.gray)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final chat = filtered[i];
                        final isOn =
                            _selected.contains(chat.phone);
                        final initials =
                            _initials(chat.customerName);

                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (isOn) {
                                _selected.remove(chat.phone);
                              } else {
                                _selected.add(chat.phone);
                              }
                            });
                          },
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isOn
                                ? KaapavTheme.gold
                                : const Color(0xFFE5E7EB),
                            child: isOn
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : Text(
                                    initials,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: widget.isDark
                                          ? const Color(0xFFF2E8D0)
                                          : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                          ),
                          title: Text(
                            chat.customerName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isOn
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            chat.phone,
                            style: const TextStyle(
                                fontSize: 12,
                                color: KaapavTheme.gray),
                          ),
                          trailing: isOn
                              ? const Icon(Icons.check_circle,
                                  color: KaapavTheme.gold, size: 22)
                              : null,
                        );
                      },
                    ),
            ),

            // ── Send button ──
            if (_selected.isNotEmpty)
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          widget.onForward(_selected.toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KaapavTheme.gold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(
                        'Forward to ${_selected.length} chat${_selected.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}  
