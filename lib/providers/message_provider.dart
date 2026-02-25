// lib/providers/message_provider.dart
// ═══════════════════════════════════════════════════════════════
// MESSAGE PROVIDER — Riverpod State Management
// Aligned with: Message model, MessageApi
// Features: Optimistic send, polling, status updates
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/notification_service.dart';
import '../services/api/message_api.dart';
import '../providers/chat_provider.dart';
import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════
// STATE CLASS
// ═══════════════════════════════════════════════════════════════

class MessageState {
  final Map<String, List<Message>> messagesByPhone;
  final Map<String, bool> loadingByPhone;
  final Map<String, bool> hasMoreByPhone;
  final Map<String, String?> errorByPhone;
  final bool isSending;

  const MessageState({
    this.messagesByPhone = const {},
    this.loadingByPhone = const {},
    this.hasMoreByPhone = const {},
    this.errorByPhone = const {},
    this.isSending = false,
  });

  MessageState copyWith({
    Map<String, List<Message>>? messagesByPhone,
    Map<String, bool>? loadingByPhone,
    Map<String, bool>? hasMoreByPhone,
    Map<String, String?>? errorByPhone,
    bool? isSending,
  }) {
    return MessageState(
      messagesByPhone: messagesByPhone ?? this.messagesByPhone,
      loadingByPhone: loadingByPhone ?? this.loadingByPhone,
      hasMoreByPhone: hasMoreByPhone ?? this.hasMoreByPhone,
      errorByPhone: errorByPhone ?? this.errorByPhone,
      isSending: isSending ?? this.isSending,
    );
  }

  List<Message> getMessages(String phone) => messagesByPhone[phone] ?? [];
  bool isLoading(String phone) => loadingByPhone[phone] ?? false;
  bool hasMore(String phone) => hasMoreByPhone[phone] ?? true;
  String? getError(String phone) => errorByPhone[phone];
}

// ═══════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════

class MessageNotifier extends StateNotifier<MessageState> {
  final MessageApi _messageApi;
  final Ref _ref;
  Timer? _pollTimer;
  String? _currentPollingPhone;

  MessageNotifier(this._messageApi, this._ref) : super(const MessageState());

  // ─────────────────────────────────────────────────────────────
  // FETCH MESSAGES
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchMessages(String phone, {bool refresh = false}) async {
    if (state.isLoading(phone) && !refresh) return;

    state = state.copyWith(
      loadingByPhone: {...state.loadingByPhone, phone: true},
      errorByPhone: {...state.errorByPhone, phone: null},
    );

    try {
      final response = await _messageApi.getMessages(phone, limit: 50);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final messagesList = (data['messages'] as List? ?? [])
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by timestamp (oldest first for display)
        messagesList.sort((a, b) {
          final aTime = a.timestamp ?? '';
          final bTime = b.timestamp ?? '';
          return bTime.compareTo(aTime);
        });

        state = state.copyWith(
          messagesByPhone: {...state.messagesByPhone, phone: messagesList},
          loadingByPhone: {...state.loadingByPhone, phone: false},
          hasMoreByPhone: {...state.hasMoreByPhone, phone: data['hasMore'] == true},
        );

        AppLogger.info('💬 Loaded ${messagesList.length} messages for $phone');
      } else {
        throw Exception(response.data?['error'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      AppLogger.error('❌ Fetch messages failed', e);
      state = state.copyWith(
        loadingByPhone: {...state.loadingByPhone, phone: false},
        errorByPhone: {...state.errorByPhone, phone: e.toString()},
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEND TEXT MESSAGE (Optimistic)
  // ─────────────────────────────────────────────────────────────

  Future<bool> sendText(String phone, String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || state.isSending) return false;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = Message(
      messageId: tempId,
      phone: phone,
      text: trimmedText,
      messageType: 'text',
      direction: 'outgoing',
      status: 'sending',
      timestamp: DateTime.now().toIso8601String(),
    );

    // Optimistic add
    final currentMessages = List<Message>.from(state.getMessages(phone));
    currentMessages.add(tempMessage);

    state = state.copyWith(
      messagesByPhone: {...state.messagesByPhone, phone: currentMessages},
      isSending: true,
    );

    // Update chat list
    _ref.read(chatProvider.notifier).onNewMessage(
      phone: phone,
      text: trimmedText,
      messageType: 'text',
      direction: 'outgoing',
    );

    try {
      final response = await _messageApi.sendText(phone, trimmedText);

      if (response.statusCode == 200 && response.data?['success'] == true) {
        _updateMessageStatus(phone, tempId, 'sent',
            realId: response.data?['messageId']?.toString());
        AppLogger.success('✅ Message sent to $phone');
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Send failed');
      }
    } catch (e) {
      AppLogger.error('❌ Send message failed', e);
      _updateMessageStatus(phone, tempId, 'failed');
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEND BUTTONS MESSAGE
  // ─────────────────────────────────────────────────────────────

  Future<bool> sendButtons(
    String phone,
    String text,
    List<Map<String, String>> buttons,
  ) async {
    if (state.isSending) return false;

    state = state.copyWith(isSending: true);

    try {
      final response = await _messageApi.sendButtons(phone, text, buttons);

      if (response.statusCode == 200 && response.data?['success'] == true) {
        await fetchMessages(phone, refresh: true);
        _ref.read(chatProvider.notifier).onNewMessage(
          phone: phone,
          text: text,
          messageType: 'buttons',
          direction: 'outgoing',
        );
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Send failed');
      }
    } catch (e) {
      AppLogger.error('❌ Send buttons failed', e);
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEND TEMPLATE
  // ─────────────────────────────────────────────────────────────

  Future<bool> sendTemplate(
    String phone,
    String templateName, {
    List<String> params = const [],
  }) async {
    if (state.isSending) return false;

    state = state.copyWith(isSending: true);

    try {
      final response = await _messageApi.sendTemplate(
        phone,
        templateName,
        params: params,
      );

      if (response.statusCode == 200 && response.data?['success'] == true) {
        await fetchMessages(phone, refresh: true);
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Send failed');
      }
    } catch (e) {
      AppLogger.error('❌ Send template failed', e);
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEND IMAGE
  // ─────────────────────────────────────────────────────────────

  Future<bool> sendImage(String phone, String mediaUrl, {String? caption}) async {
    if (state.isSending) return false;

    state = state.copyWith(isSending: true);

    try {
      final response = await _messageApi.sendImage(phone, mediaUrl, caption: caption);

      if (response.statusCode == 200 && response.data?['success'] == true) {
        await fetchMessages(phone, refresh: true);
        _ref.read(chatProvider.notifier).onNewMessage(
          phone: phone,
          text: caption ?? '📷 Photo',
          messageType: 'image',
          direction: 'outgoing',
        );
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Send failed');
      }
    } catch (e) {
      AppLogger.error('❌ Send image failed', e);
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEND DOCUMENT
  // ─────────────────────────────────────────────────────────────

  Future<bool> sendDocument(
    String phone,
    String mediaUrl, {
    String? filename,
    String? caption,
  }) async {
    if (state.isSending) return false;

    state = state.copyWith(isSending: true);

    try {
      final response = await _messageApi.sendDocument(
        phone,
        mediaUrl,
        filename: filename,
        caption: caption,
      );

      if (response.statusCode == 200 && response.data?['success'] == true) {
        await fetchMessages(phone, refresh: true);
        _ref.read(chatProvider.notifier).onNewMessage(
          phone: phone,
          text: filename ?? '📄 Document',
          messageType: 'document',
          direction: 'outgoing',
        );
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Send failed');
      }
    } catch (e) {
      AppLogger.error('❌ Send document failed', e);
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE MESSAGE STATUS
  // ─────────────────────────────────────────────────────────────

  void _updateMessageStatus(String phone, String messageId, String status, {String? realId}) {
    final currentMessages = List<Message>.from(state.getMessages(phone));
    final index = currentMessages.indexWhere((m) => m.messageId == messageId);

    if (index >= 0) {
      currentMessages[index] = currentMessages[index].copyWith(
        status: status,
        messageId: realId ?? currentMessages[index].messageId,
      );

      state = state.copyWith(
        messagesByPhone: {...state.messagesByPhone, phone: currentMessages},
      );
    }
  }

  void updateStatus(String phone, String messageId, String status) {
    _updateMessageStatus(phone, messageId, status);
  }

  // ─────────────────────────────────────────────────────────────
  // ADD INCOMING MESSAGE (from WebSocket/polling)
  // ─────────────────────────────────────────────────────────────

  void addMessage(String phone, Message message) {
    final currentMessages = List<Message>.from(state.getMessages(phone));

    // Dedup check
    final exists = currentMessages.any((m) => m.messageId == message.messageId);

    if (!exists) {
      currentMessages.add(message);

      // Sort by timestamp
      currentMessages.sort((a, b) {
        final aTime = a.timestamp ?? '';
        final bTime = b.timestamp ?? '';
        return bTime.compareTo(aTime);
      });

      state = state.copyWith(
        messagesByPhone: {...state.messagesByPhone, phone: currentMessages},
      );

      // Update chat list
      _ref.read(chatProvider.notifier).onNewMessage(
        phone: phone,
        text: message.displayText,
        messageType: message.messageType,
        direction: message.direction,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // POLLING
  // ─────────────────────────────────────────────────────────────

  void startPolling(String phone, {Duration interval = const Duration(seconds: 2)}) {
    stopPolling();
    _currentPollingPhone = phone;

    // Fetch immediately
    _pollForNewMessages(phone);

    _pollTimer = Timer.periodic(interval, (_) {
      if (_currentPollingPhone == phone) {
        _pollForNewMessages(phone);
      }
    });

    AppLogger.info('🔄 Started polling for $phone (every ${interval.inSeconds}s)');
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentPollingPhone = null;
  }

  Future<void> _pollForNewMessages(String phone) async {
    try {
      final response = await _messageApi.getMessages(phone, limit: 20);

      if (response.statusCode == 200 && response.data != null) {
        final newMessages = (response.data['messages'] as List? ?? [])
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();

        final currentMessages = state.getMessages(phone);
        final currentIds = currentMessages.map((m) => m.messageId).toSet();

        // Find new messages
        final newOnly = newMessages.where((m) => !currentIds.contains(m.messageId)).toList();

        if (newOnly.isNotEmpty) {
  for (final msg in newOnly) {
    addMessage(phone, msg);
    
    // Show notification for incoming messages
    if (msg.direction == 'incoming') {
      final chat = _ref.read(chatProvider).getChatByPhone(phone);
      final name = chat?.customerName ?? phone;
      
      NotificationService.instance.showMessageNotification(
        phone: phone,
        name: name,
        message: msg.displayText,
      );
    }
  }
  AppLogger.info('📨 Received ${newOnly.length} new messages');
}
      }
    } catch (e) {
      // Silent fail for polling
      AppLogger.warn('Poll failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RETRY FAILED MESSAGE
  // ─────────────────────────────────────────────────────────────

  Future<bool> retryMessage(String phone, String messageId) async {
    final messages = state.getMessages(phone);
    final index = messages.indexWhere((m) => m.messageId == messageId);
    if (index < 0) return false;

    final message = messages[index];
    if (message.status != 'failed') return false;

    // Update status to sending
    _updateMessageStatus(phone, messageId, 'sending');

    try {
      final response = await _messageApi.sendText(phone, message.text ?? '');

      if (response.statusCode == 200 && response.data?['success'] == true) {
        _updateMessageStatus(phone, messageId, 'sent',
            realId: response.data?['messageId']?.toString());
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Retry failed');
      }
    } catch (e) {
      _updateMessageStatus(phone, messageId, 'failed');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CLEAR / RESET
  // ─────────────────────────────────────────────────────────────

  void clearMessages(String phone) {
    final updated = Map<String, List<Message>>.from(state.messagesByPhone);
    updated.remove(phone);
    state = state.copyWith(messagesByPhone: updated);
  }

  void reset() {
    stopPolling();
    state = const MessageState();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

final messageApiProvider = Provider<MessageApi>((ref) => MessageApi());

final messageProvider = StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  return MessageNotifier(ref.watch(messageApiProvider), ref);
});

// Selector for specific phone's messages
final messagesForPhoneProvider = Provider.family<List<Message>, String>((ref, phone) {
  return ref.watch(messageProvider).getMessages(phone);
});

// Selector for current chat messages
final currentMessagesProvider = Provider<List<Message>>((ref) {
  final phone = ref.watch(chatProvider).currentChatPhone;
  if (phone == null) return [];
  return ref.watch(messageProvider).getMessages(phone);
});

final isSendingProvider = Provider<bool>((ref) {
  return ref.watch(messageProvider).isSending;
});