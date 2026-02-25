// lib/providers/chat_provider.dart
// ═══════════════════════════════════════════════════════════════
// CHAT PROVIDER — Riverpod State Management
// Aligned with: Chat model, ChatApi
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/customer.dart';
import '../services/api/chat_api.dart';
import '../utils/logger.dart';
import '../utils/formatters.dart';

// ═══════════════════════════════════════════════════════════════
// STATE CLASS
// ═══════════════════════════════════════════════════════════════

class ChatState {
  final List<Chat> chats;
  final String? currentChatPhone;
  final Customer? currentCustomer;
  final Map<String, bool> typingStatus;
  final Map<String, String> onlineStatus;
  final int unreadTotal;
  final bool isLoading;
  final String? error;
  final DateTime? lastSync;

  const ChatState({
    this.chats = const [],
    this.currentChatPhone,
    this.currentCustomer,
    this.typingStatus = const {},
    this.onlineStatus = const {},
    this.unreadTotal = 0,
    this.isLoading = false,
    this.error,
    this.lastSync,
  });

  ChatState copyWith({
    List<Chat>? chats,
    String? currentChatPhone,
    Customer? currentCustomer,
    Map<String, bool>? typingStatus,
    Map<String, String>? onlineStatus,
    int? unreadTotal,
    bool? isLoading,
    String? error,
    DateTime? lastSync,
    bool clearCurrentChat = false,
    bool clearCustomer = false,
    bool clearError = false,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      currentChatPhone: clearCurrentChat ? null : (currentChatPhone ?? this.currentChatPhone),
      currentCustomer: clearCustomer ? null : (currentCustomer ?? this.currentCustomer),
      typingStatus: typingStatus ?? this.typingStatus,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      unreadTotal: unreadTotal ?? this.unreadTotal,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastSync: lastSync ?? this.lastSync,
    );
  }

  Chat? get currentChat {
    if (currentChatPhone == null) return null;
    final index = chats.indexWhere((c) => c.phone == currentChatPhone);
    return index >= 0 ? chats[index] : null;
  }

  Chat? getChatByPhone(String phone) {
    final index = chats.indexWhere((c) => c.phone == phone);
    return index >= 0 ? chats[index] : null;
  }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatApi _chatApi;
  Timer? _autoRefreshTimer;

  ChatNotifier(this._chatApi) : super(const ChatState());

  // ─────────────────────────────────────────────────────────────
  // FETCH CHATS (aliased as loadChats)
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchChats({
    String? status,
    String? search,
    String? label,
    bool? starred,
    bool silent = false,
  }) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final response = await _chatApi.getChats(
        status: status,
        search: search,
        label: label,
        starred: starred,
        limit: 50,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final chatsList = (data['chats'] as List? ?? [])
            .map((json) => Chat.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by lastTimestamp (newest first)
        chatsList.sort((a, b) {
          final aTime = Formatters.parseDate(a.lastTimestamp);
          final bTime = Formatters.parseDate(b.lastTimestamp);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        final unreadTotal = chatsList.fold<int>(
          0,
          (sum, chat) => sum + chat.unreadCount,
        );

        state = state.copyWith(
          chats: chatsList,
          unreadTotal: unreadTotal,
          isLoading: false,
          lastSync: DateTime.now(),
        );

        AppLogger.info('📋 Loaded ${chatsList.length} chats (unread: $unreadTotal)');
      } else {
        throw Exception(response.data?['error'] ?? 'Failed to fetch chats');
      }
    } catch (e) {
      AppLogger.error('❌ Fetch chats failed', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Alias for fetchChats (used by existing screens)
  Future<void> loadChats({bool silent = false}) async {
    return fetchChats(silent: silent);
  }

  // ─────────────────────────────────────────────────────────────
  // AUTO REFRESH
  // ─────────────────────────────────────────────────────────────

  void startAutoRefresh({Duration interval = const Duration(seconds: 2)}) {
    stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      fetchChats(silent: true);
    });
    AppLogger.info('🔄 Auto refresh started (${interval.inSeconds}s)');
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  // ─────────────────────────────────────────────────────────────
  // SET CURRENT CHAT
  // ─────────────────────────────────────────────────────────────

  Future<void> setCurrentChat(String phone) async {
    state = state.copyWith(
      currentChatPhone: phone,
      clearCustomer: true,
    );

    // Fetch customer details
    try {
      final response = await _chatApi.getCustomer(phone);
      if (response.statusCode == 200 && response.data != null) {
        final customerData = response.data['customer'];
        if (customerData != null) {
          state = state.copyWith(
            currentCustomer: Customer.fromJson(customerData as Map<String, dynamic>),
          );
        }
      }
    } catch (e) {
      AppLogger.warn('Customer fetch failed: $e');
    }
  }

  void clearCurrentChat() {
    state = state.copyWith(
      clearCurrentChat: true,
      clearCustomer: true,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MARK AS READ (aliased as markRead)
  // ─────────────────────────────────────────────────────────────

  Future<void> markAsRead(String phone) async {
    final chat = state.getChatByPhone(phone);
    if (chat == null || chat.unreadCount == 0) return;

    // Optimistic update
    final updatedChats = state.chats.map((c) {
      if (c.phone == phone) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();

    final newUnreadTotal = updatedChats.fold<int>(
      0,
      (sum, c) => sum + c.unreadCount,
    );

    state = state.copyWith(
      chats: updatedChats,
      unreadTotal: newUnreadTotal,
    );

    // API call (non-blocking)
    try {
      await _chatApi.markAsRead(phone);
    } catch (e) {
      AppLogger.warn('Mark read API failed: $e');
    }
  }

  /// Alias for markAsRead (used by existing screens)
  Future<void> markRead(String phone) async {
    return markAsRead(phone);
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE CHAT (optimistic)
  // ─────────────────────────────────────────────────────────────

  void updateChat(String phone, {
    String? lastMessage,
    String? lastMessageType,
    String? lastDirection,
    int? unreadCount,
    bool? isStarred,
    bool? isBlocked,
    bool? isBotEnabled,
  }) {
    final updatedChats = state.chats.map((chat) {
      if (chat.phone == phone) {
        return chat.copyWith(
          lastMessage: lastMessage,
          lastMessageType: lastMessageType,
          lastDirection: lastDirection,
          unreadCount: unreadCount,
          isStarred: isStarred,
          isBlocked: isBlocked,
          isBotEnabled: isBotEnabled,
          lastTimestamp: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
      return chat;
    }).toList();

    // Re-sort by timestamp
    updatedChats.sort((a, b) {
      final aTime = Formatters.parseDate(a.lastTimestamp);
      final bTime = Formatters.parseDate(b.lastTimestamp);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    final newUnreadTotal = updatedChats.fold<int>(
      0,
      (sum, c) => sum + c.unreadCount,
    );

    state = state.copyWith(
      chats: updatedChats,
      unreadTotal: newUnreadTotal,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ON NEW MESSAGE
  // ─────────────────────────────────────────────────────────────

  void onNewMessage({
    required String phone,
    required String text,
    required String messageType,
    required String direction,
    String? customerName,
  }) {
    final existingIndex = state.chats.indexWhere((c) => c.phone == phone);
    final isIncoming = direction == 'incoming' || direction == 'in';
    final isCurrentChat = state.currentChatPhone == phone;
    final now = DateTime.now().toIso8601String();

    if (existingIndex >= 0) {
      final existingChat = state.chats[existingIndex];
      final updatedChats = List<Chat>.from(state.chats);

      updatedChats[existingIndex] = existingChat.copyWith(
        lastMessage: text,
        lastMessageType: messageType,
        lastDirection: direction,
        lastTimestamp: now,
        updatedAt: now,
        unreadCount: isIncoming && !isCurrentChat
            ? existingChat.unreadCount + 1
            : existingChat.unreadCount,
        totalMessages: existingChat.totalMessages + 1,
      );

      // Move to top
      final chat = updatedChats.removeAt(existingIndex);
      updatedChats.insert(0, chat);

      final newUnreadTotal = updatedChats.fold<int>(0, (sum, c) => sum + c.unreadCount);

      state = state.copyWith(
        chats: updatedChats,
        unreadTotal: newUnreadTotal,
      );
    } else {
      // New chat
      final newChat = Chat(
        phone: phone,
        customerName: customerName ?? phone,
        lastMessage: text,
        lastMessageType: messageType,
        lastDirection: direction,
        lastTimestamp: now,
        unreadCount: isIncoming ? 1 : 0,
        totalMessages: 1,
        status: 'open',
        priority: 'normal',
        isBotEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      state = state.copyWith(
        chats: [newChat, ...state.chats],
        unreadTotal: state.unreadTotal + (isIncoming ? 1 : 0),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TYPING & ONLINE STATUS
  // ─────────────────────────────────────────────────────────────

  void setTyping(String phone, bool isTyping) {
    state = state.copyWith(
      typingStatus: {...state.typingStatus, phone: isTyping},
    );
  }

  void setOnlineStatus(String phone, String status) {
    state = state.copyWith(
      onlineStatus: {...state.onlineStatus, phone: status},
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TOGGLE ACTIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> toggleStar(String phone) async {
    final chat = state.getChatByPhone(phone);
    if (chat == null) return;

    final newValue = !chat.isStarred;
    updateChat(phone, isStarred: newValue);

    try {
      await _chatApi.toggleStar(phone, newValue);
    } catch (e) {
      updateChat(phone, isStarred: !newValue);
      AppLogger.error('Toggle star failed', e);
    }
  }

  Future<void> toggleBot(String phone) async {
    final chat = state.getChatByPhone(phone);
    if (chat == null) return;

    final newValue = !chat.isBotEnabled;
    updateChat(phone, isBotEnabled: newValue);

    try {
      await _chatApi.toggleBot(phone, newValue);
    } catch (e) {
      updateChat(phone, isBotEnabled: !newValue);
      AppLogger.error('Toggle bot failed', e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────────────────────

  void reset() {
    stopAutoRefresh();
    state = const ChatState();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

final chatApiProvider = Provider<ChatApi>((ref) => ChatApi());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatApiProvider));
});

// Selectors
final currentChatProvider = Provider<Chat?>((ref) {
  return ref.watch(chatProvider).currentChat;
});

final currentCustomerProvider = Provider<Customer?>((ref) {
  return ref.watch(chatProvider).currentCustomer;
});

final unreadTotalProvider = Provider<int>((ref) {
  return ref.watch(chatProvider).unreadTotal;
});

final chatsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isLoading;
});