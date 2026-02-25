// lib/services/api/chat_api.dart
// ═══════════════════════════════════════════════════════════
// CHAT & CUSTOMER API
// Matches: worker/handlers/chat.js
// ═══════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import '../../config/constants.dart';
import 'api_client.dart';

class ChatApi {
  final ApiClient _client = ApiClient.instance;

  // ═══════════════════════════════════════════════════════════
  // CHAT LIST
  // GET /api/chats?status=&search=&label=&starred=&limit=&offset=
  // Response: { chats[], total, unread, limit, offset }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getChats({
    String? status,
    String? search,
    String? label,
    bool? starred,
    String? assigned,
    int limit = 50,
    int offset = 0,
    CancelToken? cancelToken,
  }) {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != null) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (label != null) params['label'] = label;
    if (starred == true) params['starred'] = 'true';
    if (assigned != null) params['assigned'] = assigned;

    return _client.get(
      ApiEndpoints.chats,
      queryParameters: params,
      cacheTTL: const Duration(seconds: 10),
      cancelToken: cancelToken,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SINGLE CHAT (with customer + recent orders)
  // GET /api/chats/:phone
  // Response: { phone, name, ..., customer: {}, orders[] }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getChat(String phone) {
    return _client.get(
      ApiEndpoints.chat(phone),
      cacheTTL: const Duration(seconds: 10),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE CHAT (star, block, bot, status, priority, labels)
  // PUT /api/chats/:phone
  // Body: { is_starred, is_blocked, is_bot_enabled, status, priority, labels, assigned_to }
  // ═══════════════════════════════════════════════════════════

  Future<Response> updateChat(String phone, Map<String, dynamic> data) {
    return _client.put(ApiEndpoints.chat(phone), data: data);
  }

  /// Convenience: Toggle star
  Future<Response> toggleStar(String phone, bool isStarred) {
    return updateChat(phone, {'is_starred': isStarred});
  }

  /// Convenience: Toggle block
  Future<Response> toggleBlock(String phone, bool isBlocked) {
    return updateChat(phone, {'is_blocked': isBlocked});
  }

  /// Convenience: Toggle bot
  Future<Response> toggleBot(String phone, bool botEnabled) {
    return updateChat(phone, {'is_bot_enabled': botEnabled});
  }

  /// Convenience: Set priority
  Future<Response> setPriority(String phone, String priority) {
    return updateChat(phone, {'priority': priority});
  }

  /// Convenience: Set status
  Future<Response> setStatus(String phone, String status) {
    return updateChat(phone, {'status': status});
  }

  // ═══════════════════════════════════════════════════════════
  // MARK AS READ
  // POST /api/chats/:phone/read
  // ═══════════════════════════════════════════════════════════

  Future<Response> markAsRead(String phone) {
    return _client.post(ApiEndpoints.chatMarkRead(phone));
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE LABELS
  // POST /api/chats/:phone/labels
  // Body: { labels: ["VIP", "Hot Lead"] }
  // ═══════════════════════════════════════════════════════════

  Future<Response> updateLabels(String phone, List<String> labels) {
    return _client.post(
      ApiEndpoints.chatLabels(phone),
      data: {'labels': labels},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ASSIGN AGENT
  // POST /api/chats/:phone/assign
  // Body: { agentId: "usr_xxx" }
  // ═══════════════════════════════════════════════════════════

  Future<Response> assignChat(String phone, String? agentId) {
    return _client.post(
      '/api/chats/$phone/assign',
      data: {'agentId': agentId},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOMERS
  // ═══════════════════════════════════════════════════════════

  /// GET /api/customers?segment=&tier=&search=&limit=&offset=
  /// Response: { customers[] }
  Future<Response> getCustomers({
    String? segment,
    String? tier,
    String? search,
    int limit = 50,
    int offset = 0,
  }) {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (segment != null) params['segment'] = segment;
    if (tier != null) params['tier'] = tier;
    if (search != null && search.isNotEmpty) params['search'] = search;

    return _client.get(
      ApiEndpoints.customers,
      queryParameters: params,
      cacheTTL: const Duration(seconds: 30),
    );
  }

  /// GET /api/customers/:phone
  /// Response: { customer: {}, orders[] }
  Future<Response> getCustomer(String phone) {
    return _client.get(
      ApiEndpoints.customer(phone),
      cacheTTL: const Duration(seconds: 30),
    );
  }

  /// PUT /api/customers/:phone
  /// Body: { name, email, segment, tier, labels, address, city, state, pincode }
  Future<Response> updateCustomer(String phone, Map<String, dynamic> data) {
    return _client.put(ApiEndpoints.customer(phone), data: data);
  }
}