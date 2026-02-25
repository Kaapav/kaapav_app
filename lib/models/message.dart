class Message {
  final int? id;
  final String messageId;
  final String phone;
  final String? text;
  final String messageType;
  final String direction;
  final String? mediaId;
  final String? mediaUrl;
  final String? mediaMime;
  final String? mediaCaption;
  final String? buttonId;
  final String? buttonText;
  final dynamic buttons;
  final bool isMenu;
  final String? listId;
  final String? listTitle;
  final String? contextMessageId;
  final bool isForwarded;
  final String status;
  final bool isAutoReply;
  final bool isTemplate;
  final String? templateName;
  final String? timestamp;
  final String? deliveredAt;
  final String? readAt;
  final String? createdAt;

  const Message({
    this.id,
    this.messageId = '',
    this.phone = '',
    this.text,
    this.messageType = 'text',
    this.direction = 'outgoing',
    this.mediaId,
    this.mediaUrl,
    this.mediaMime,
    this.mediaCaption,
    this.buttonId,
    this.buttonText,
    this.buttons,
    this.isMenu = false,
    this.listId,
    this.listTitle,
    this.contextMessageId,
    this.isForwarded = false,
    this.status = 'sent',
    this.isAutoReply = false,
    this.isTemplate = false,
    this.templateName,
    this.timestamp,
    this.deliveredAt,
    this.readAt,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      messageId: json['message_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      text: json['text'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      direction: json['direction'] as String? ?? 'outgoing',
      mediaId: json['media_id'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaMime: json['media_mime'] as String?,
      mediaCaption: json['media_caption'] as String?,
      buttonId: json['button_id'] as String?,
      buttonText: json['button_text'] as String?,
      buttons: json['buttons'],
      isMenu: json['is_menu'] == 1 || json['is_menu'] == true,
      listId: json['list_id'] as String?,
      listTitle: json['list_title'] as String?,
      contextMessageId: json['context_message_id'] as String?,
      isForwarded: json['is_forwarded'] == 1 || json['is_forwarded'] == true,
      status: json['status'] as String? ?? 'sent',
      isAutoReply: json['is_auto_reply'] == 1 || json['is_auto_reply'] == true,
      isTemplate: json['is_template'] == 1 || json['is_template'] == true,
      templateName: json['template_name'] as String?,
      timestamp: json['timestamp'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_id': messageId,
        'phone': phone,
        'text': text,
        'message_type': messageType,
        'direction': direction,
        'media_id': mediaId,
        'media_url': mediaUrl,
        'media_mime': mediaMime,
        'media_caption': mediaCaption,
        'button_id': buttonId,
        'button_text': buttonText,
        'buttons': buttons,
        'is_menu': isMenu ? 1 : 0,
        'list_id': listId,
        'list_title': listTitle,
        'context_message_id': contextMessageId,
        'is_forwarded': isForwarded ? 1 : 0,
        'status': status,
        'is_auto_reply': isAutoReply ? 1 : 0,
        'is_template': isTemplate ? 1 : 0,
        'template_name': templateName,
        'timestamp': timestamp,
        'delivered_at': deliveredAt,
        'read_at': readAt,
        'created_at': createdAt,
      };

  Message copyWith({
    int? id,
    String? messageId,
    String? phone,
    String? text,
    String? messageType,
    String? direction,
    String? mediaId,
    String? mediaUrl,
    String? mediaMime,
    String? mediaCaption,
    String? buttonId,
    String? buttonText,
    dynamic buttons,
    bool? isMenu,
    String? listId,
    String? listTitle,
    String? contextMessageId,
    bool? isForwarded,
    String? status,
    bool? isAutoReply,
    bool? isTemplate,
    String? templateName,
    String? timestamp,
    String? deliveredAt,
    String? readAt,
    String? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      phone: phone ?? this.phone,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      direction: direction ?? this.direction,
      mediaId: mediaId ?? this.mediaId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMime: mediaMime ?? this.mediaMime,
      mediaCaption: mediaCaption ?? this.mediaCaption,
      buttonId: buttonId ?? this.buttonId,
      buttonText: buttonText ?? this.buttonText,
      buttons: buttons ?? this.buttons,
      isMenu: isMenu ?? this.isMenu,
      listId: listId ?? this.listId,
      listTitle: listTitle ?? this.listTitle,
      contextMessageId: contextMessageId ?? this.contextMessageId,
      isForwarded: isForwarded ?? this.isForwarded,
      status: status ?? this.status,
      isAutoReply: isAutoReply ?? this.isAutoReply,
      isTemplate: isTemplate ?? this.isTemplate,
      templateName: templateName ?? this.templateName,
      timestamp: timestamp ?? this.timestamp,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── Convenience getters ──
  bool get isIncoming => direction == 'incoming';
  bool get isOutgoing => direction == 'outgoing';
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read';
  bool get isFailed => status == 'failed';
  bool get isSending => status == 'sending';
  bool get hasMedia =>
      messageType == 'image' ||
      messageType == 'video' ||
      messageType == 'document' ||
      messageType == 'audio';

  String get displayText {
    if (text != null && text!.isNotEmpty) return text!;
    if (mediaCaption != null && mediaCaption!.isNotEmpty) return mediaCaption!;
    switch (messageType) {
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
        return '';
    }
  }
}