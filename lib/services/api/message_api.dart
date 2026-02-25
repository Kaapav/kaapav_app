// lib/services/api/message_api.dart
// ═══════════════════════════════════════════════════════════
// MESSAGE API
// Matches: worker/handlers/message.js + chat.js (getMessages)
// ═══════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import '../../config/constants.dart';
import 'api_client.dart';

class MessageApi {
  final ApiClient _client = ApiClient.instance;

  // ═══════════════════════════════════════════════════════════
  // GET MESSAGES
  // GET /api/chats/:phone/messages?limit=50&before=123
  // Response: { messages[], hasMore }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getMessages(
    String phone, {
    int limit = 50,
    int? before,
    CancelToken? cancelToken,
  }) {
    final params = <String, dynamic>{'limit': limit};
    if (before != null) params['before'] = before;

    return _client.get(
      ApiEndpoints.messages(phone),
      queryParameters: params,
      cacheTTL: const Duration(seconds: 5),
      cancelToken: cancelToken,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND TEXT MESSAGE
  // POST /api/messages/send
  // Body: { phone, type: "text", text }
  // Response: { success, messageId }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendText(String phone, String text) {
    return _client.post(
      ApiEndpoints.sendMessage,
      data: {
        'phone': phone,
        'type': 'text',
        'text': text,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND BUTTON MESSAGE
  // POST /api/messages/send
  // Body: { phone, type: "buttons", text, buttons: [{id, title}] }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendButtons(
    String phone,
    String text,
    List<Map<String, String>> buttons,
  ) {
    return _client.post(
      ApiEndpoints.sendMessage,
      data: {
        'phone': phone,
        'type': 'buttons',
        'text': text,
        'buttons': buttons,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND LIST MESSAGE
  // POST /api/messages/send
  // Body: { phone, type: "list", text, list: { buttonText, sections[] } }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendList(
    String phone,
    String text,
    Map<String, dynamic> list,
  ) {
    return _client.post(
      ApiEndpoints.sendMessage,
      data: {
        'phone': phone,
        'type': 'list',
        'text': text,
        'list': list,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND IMAGE
  // POST /api/messages/send
  // Body: { phone, type: "image", mediaUrl, mediaCaption }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendImage(
    String phone,
    String mediaUrl, {
    String? caption,
  }) {
    return _client.post(
      ApiEndpoints.sendMessage,
      data: {
        'phone': phone,
        'type': 'image',
        'mediaUrl': mediaUrl,
        'mediaCaption': caption,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND DOCUMENT
  // POST /api/messages/send
  // Body: { phone, type: "document", mediaUrl, filename, mediaCaption }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendDocument(
    String phone,
    String mediaUrl, {
    String? filename,
    String? caption,
  }) {
    return _client.post(
      ApiEndpoints.sendMessage,
      data: {
        'phone': phone,
        'type': 'document',
        'mediaUrl': mediaUrl,
        'filename': filename,
        'mediaCaption': caption,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND LOCATION
  // POST /api/messages/send
  // Body: { phone, type: "location", location: { latitude, longitude, name, address } }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendLocation(
    String phone, {
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) {
    return _client.post(
      ApiEndpoints.sendMessage,
      data: {
        'phone': phone,
        'type': 'location',
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'name': name,
          'address': address,
        },
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND TEMPLATE
  // POST /api/messages/send-template
  // Body: { phone, templateName, params[], language }
  // Response: { success, messageId }
  // ═══════════════════════════════════════════════════════════

  Future<Response> sendTemplate(
    String phone,
    String templateName, {
    List<String> params = const [],
    String language = 'en',
  }) {
    return _client.post(
      ApiEndpoints.sendTemplate,
      data: {
        'phone': phone,
        'templateName': templateName,
        'params': params,
        'language': language,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BULK SEND (max 50 recipients)
  // POST /api/messages/bulk-send
  // Body: { phones[], type, text, buttons?, templateName?, params? }
  // Response: { success, message, count }
  // ═══════════════════════════════════════════════════════════

  Future<Response> bulkSend(
    List<String> phones, {
    required String text,
    String type = 'text',
    List<Map<String, String>>? buttons,
    String? templateName,
    List<String>? params,
  }) {
    return _client.post(
      ApiEndpoints.bulkSend,
      data: {
        'phones': phones,
        'type': type,
        'text': text,
        if (buttons != null) 'buttons': buttons,
        if (templateName != null) 'templateName': templateName,
        if (params != null) 'params': params,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MARK AS READ (WhatsApp-side)
  // POST /api/messages/mark-read
  // Body: { messageId }
  // ═══════════════════════════════════════════════════════════

  Future<Response> markAsRead(String messageId) {
    return _client.post(
      ApiEndpoints.markRead,
      data: {'messageId': messageId},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // QUICK REPLIES
  // GET /api/messages/quick-replies?category=
  // Response: { quickReplies[] }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getQuickReplies({String? category}) {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;

    return _client.get(
      '/api/messages/quick-replies',
      queryParameters: params,
      cacheTTL: const Duration(minutes: 2),
    );
  }
}