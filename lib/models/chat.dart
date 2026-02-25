class Chat {
  final int? id;
  final String phone;
  final String customerName;
  final String? lastMessage;
  final String? lastMessageType;
  final String? lastTimestamp;
  final String? lastDirection;
  final int unreadCount;
  final int totalMessages;
  final String? assignedTo;
  final String status;
  final String priority;
  final List<String> labels;
  final bool isStarred;
  final bool isBlocked;
  final bool isBotEnabled;
  final String? createdAt;
  final String? updatedAt;

  const Chat({
    this.id,
    this.phone = '',
    this.customerName = '',
    this.lastMessage,
    this.lastMessageType,
    this.lastTimestamp,
    this.lastDirection,
    this.unreadCount = 0,
    this.totalMessages = 0,
    this.assignedTo,
    this.status = 'open',
    this.priority = 'normal',
    this.labels = const [],
    this.isStarred = false,
    this.isBlocked = false,
    this.isBotEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as int?,
      phone: json['phone'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageType: json['last_message_type'] as String?,
      lastTimestamp: json['last_timestamp'] as String?,
      lastDirection: json['last_direction'] as String?,
      unreadCount: _toInt(json['unread_count']),
      totalMessages: _toInt(json['total_messages']),
      assignedTo: json['assigned_to'] as String?,
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String? ?? 'normal',
      labels: _parseLabels(json['labels']),
      isStarred: json['is_starred'] == 1 || json['is_starred'] == true,
      isBlocked: json['is_blocked'] == 1 || json['is_blocked'] == true,
      isBotEnabled: json['is_bot_enabled'] == 1 ||
          json['is_bot_enabled'] == true ||
          json['is_bot_enabled'] == null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'customer_name': customerName,
        'last_message': lastMessage,
        'last_message_type': lastMessageType,
        'last_timestamp': lastTimestamp,
        'last_direction': lastDirection,
        'unread_count': unreadCount,
        'total_messages': totalMessages,
        'assigned_to': assignedTo,
        'status': status,
        'priority': priority,
        'labels': labels,
        'is_starred': isStarred ? 1 : 0,
        'is_blocked': isBlocked ? 1 : 0,
        'is_bot_enabled': isBotEnabled ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Chat copyWith({
    int? id,
    String? phone,
    String? customerName,
    String? lastMessage,
    String? lastMessageType,
    String? lastTimestamp,
    String? lastDirection,
    int? unreadCount,
    int? totalMessages,
    String? assignedTo,
    String? status,
    String? priority,
    List<String>? labels,
    bool? isStarred,
    bool? isBlocked,
    bool? isBotEnabled,
    String? createdAt,
    String? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      customerName: customerName ?? this.customerName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      lastDirection: lastDirection ?? this.lastDirection,
      unreadCount: unreadCount ?? this.unreadCount,
      totalMessages: totalMessages ?? this.totalMessages,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      labels: labels ?? this.labels,
      isStarred: isStarred ?? this.isStarred,
      isBlocked: isBlocked ?? this.isBlocked,
      isBotEnabled: isBotEnabled ?? this.isBotEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static List<String> _parseLabels(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) {
      if (val.isEmpty || val == '[]') return [];
      try {
        final cleaned =
            val.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
        return cleaned
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }
}