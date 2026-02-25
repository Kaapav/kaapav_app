class QuickReply {
  final int? id;
  final String shortcut;
  final String title;
  final String message;
  final String messageType;
  final dynamic buttons;
  final dynamic listData;
  final String? mediaUrl;
  final String? category;
  final List<String> variables;
  final int useCount;
  final bool isActive;
  final String? createdAt;

  const QuickReply({
    this.id,
    this.shortcut = '',
    this.title = '',
    this.message = '',
    this.messageType = 'text',
    this.buttons,
    this.listData,
    this.mediaUrl,
    this.category,
    this.variables = const [],
    this.useCount = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: json['id'] as int?,
      shortcut: json['shortcut'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      buttons: json['buttons'],
      listData: json['list_data'],
      mediaUrl: json['media_url'] as String?,
      category: json['category'] as String?,
      variables: _parseStringList(json['variables']),
      useCount: _toInt(json['use_count']),
      isActive: json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shortcut': shortcut,
        'title': title,
        'message': message,
        'message_type': messageType,
        'buttons': buttons,
        'list_data': listData,
        'media_url': mediaUrl,
        'category': category,
        'variables': variables,
        'use_count': useCount,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  QuickReply copyWith({
    int? id,
    String? shortcut,
    String? title,
    String? message,
    String? messageType,
    dynamic buttons,
    dynamic listData,
    String? mediaUrl,
    String? category,
    List<String>? variables,
    int? useCount,
    bool? isActive,
    String? createdAt,
  }) {
    return QuickReply(
      id: id ?? this.id,
      shortcut: shortcut ?? this.shortcut,
      title: title ?? this.title,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      buttons: buttons ?? this.buttons,
      listData: listData ?? this.listData,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      category: category ?? this.category,
      variables: variables ?? this.variables,
      useCount: useCount ?? this.useCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static List<String> _parseStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) {
      if (val.isEmpty || val == '[]') return [];
      try {
        return val
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
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