// lib/screens/chats/chat_window_screen.dart
// ---------------------------------------------------------------
// CHAT WINDOW SCREEN � Full chat with polling
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
        title: const Text('Delete message?'),
        content: const Text('This will remove the message from your view.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(messageProvider.notifier).deleteMessage(widget.phone, message.messageId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: KaapavTheme.error)),
          ),
        ],
      ),
    );
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
    buffer.writeln('KAAPAV Chat Export � $name');
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

  void _handleButtonClick(String buttonId, String buttonTitle) {
    _handleSend(buttonTitle);
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

            // -- Delete --
            ListTile(
              leading: const Icon(Icons.delete_outline, color: KaapavTheme.error),
              title: const Text('Delete', style: TextStyle(color: KaapavTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _handleDelete(message);
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
      backgroundColor: const Color(0xFFFAFAD2),
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

            // -- Reply Preview Bar (NEW) --
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: KaapavTheme.cream,
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
      return AppBar(
        backgroundColor: KaapavTheme.gold,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() { _isSelecting = false; _selectedIds.clear(); }),
        ),
        title: Text('${_selectedIds.length} selected', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.star, color: Colors.white), tooltip: 'Star',
            onPressed: () {
              for (final id in _selectedIds) { ref.read(messageProvider.notifier).starMessage(widget.phone, id); }
              setState(() { _isSelecting = false; _selectedIds.clear(); });
            }),
          IconButton(icon: const Icon(Icons.delete, color: Colors.white), tooltip: 'Delete',
            onPressed: () {
              for (final id in _selectedIds) { ref.read(messageProvider.notifier).deleteMessage(widget.phone, id); }
              setState(() { _isSelecting = false; _selectedIds.clear(); });
            }),
          IconButton(icon: const Icon(Icons.share, color: Colors.white), tooltip: 'Share',
            onPressed: () {
              final msgs = ref.read(messagesForPhoneProvider(widget.phone));
              final selected = msgs.where((m) => _selectedIds.contains(m.messageId));
              final text = selected.map((m) => m.displayText).join('\n');
              Share.share(text);
              setState(() { _isSelecting = false; _selectedIds.clear(); });
            }),
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
          onSelected: (value) {
            switch (value) {
              case 'star': ref.read(chatProvider.notifier).toggleStar(widget.phone); break;
              case 'refresh': ref.read(messageProvider.notifier).fetchMessages(widget.phone, refresh: true); break;
              case 'export': _handleExportChat(); break;
              case 'select': setState(() => _isSelecting = true); break;
              case 'starred': Navigator.push(context, MaterialPageRoute(builder: (_) => const StarredMessagesScreen())); break;
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
    // Apply search filter
    var filtered = messages;
    if (_searchQuery.isNotEmpty) {
      filtered = messages.where((m) =>
        (m.text ?? '').toLowerCase().contains(_searchQuery) ||
        (m.mediaCaption ?? '').toLowerCase().contains(_searchQuery)
      ).toList();
    }

    final grouped = _groupMessagesByDate(filtered);
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
                  color: KaapavTheme.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                child: Text(_formatDateHeader(dateStr),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: KaapavTheme.gray)),
              ),
            ),
            ...dateMessages.map((message) {
              final isSelected = _selectedIds.contains(message.messageId);

              Widget bubble = ChatBubble(
                message: message,
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

              // Selection mode
              if (_isSelecting) {
                bubble = GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
  _selectedIds.remove(message.messageId);
} else {
  _selectedIds.add(message.messageId);
}
                  }),
                  child: Container(
                    color: isSelected ? KaapavTheme.gold.withValues(alpha: 0.1) : null,
                    child: Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? KaapavTheme.gold : KaapavTheme.grayLight, size: 22),
                      ),
                      Expanded(child: bubble),
                    ]),
                  ),
                );
              } else {
                // Swipe to reply
                bubble = Dismissible(
                  key: Key('swipe_${message.messageId}'),
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (_) async {
                    HapticFeedback.lightImpact();
                    setState(() => _replyingTo = message);
                    return false; // don't dismiss
                  },
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    child: const Icon(Icons.reply, color: KaapavTheme.gold, size: 28),
                  ),
                  child: bubble,
                );
              }

              return bubble;
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

  // ? Sort messages within each group by parsed DateTime (not raw string)
  grouped.forEach((key, value) {
    value.sort((a, b) {
      final aTime = Formatters.parseDate(a.timestamp);
      final bTime = Formatters.parseDate(b.timestamp);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return aTime.compareTo(bTime); // oldest ? newest (top ? bottom)
    });
  });

  // ? Sort groups newest-first (because ListView is reverse:true)
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
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}