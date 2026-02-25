class Broadcast {
  final int? id;
  final String broadcastId;
  final String name;
  final String? messageType;
  final String? message;
  final String? templateName;
  final dynamic templateParams;
  final String? mediaUrl;
  final dynamic buttons;
  final String targetType;
  final dynamic targetLabels;
  final String? targetSegment;
  final dynamic targetFilters;
  final int targetCount;
  final int sentCount;
  final int deliveredCount;
  final int readCount;
  final int failedCount;
  final int clickedCount;
  final String status;
  final String? scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final int sendRate;
  final String? createdBy;
  final String? createdAt;

  const Broadcast({
    this.id,
    this.broadcastId = '',
    this.name = '',
    this.messageType,
    this.message,
    this.templateName,
    this.templateParams,
    this.mediaUrl,
    this.buttons,
    this.targetType = 'all',
    this.targetLabels,
    this.targetSegment,
    this.targetFilters,
    this.targetCount = 0,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.readCount = 0,
    this.failedCount = 0,
    this.clickedCount = 0,
    this.status = 'draft',
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.sendRate = 30,
    this.createdBy,
    this.createdAt,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    return Broadcast(
      id: json['id'] as int?,
      broadcastId: json['broadcast_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      messageType: json['message_type'] as String?,
      message: json['message'] as String?,
      templateName: json['template_name'] as String?,
      templateParams: json['template_params'],
      mediaUrl: json['media_url'] as String?,
      buttons: json['buttons'],
      targetType: json['target_type'] as String? ?? 'all',
      targetLabels: json['target_labels'],
      targetSegment: json['target_segment'] as String?,
      targetFilters: json['target_filters'],
      targetCount: _toInt(json['target_count']),
      sentCount: _toInt(json['sent_count']),
      deliveredCount: _toInt(json['delivered_count']),
      readCount: _toInt(json['read_count']),
      failedCount: _toInt(json['failed_count']),
      clickedCount: _toInt(json['clicked_count']),
      status: json['status'] as String? ?? 'draft',
      scheduledAt: json['scheduled_at'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      sendRate: _toInt(json['send_rate']),
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'broadcast_id': broadcastId,
        'name': name,
        'message_type': messageType,
        'message': message,
        'template_name': templateName,
        'template_params': templateParams,
        'media_url': mediaUrl,
        'buttons': buttons,
        'target_type': targetType,
        'target_labels': targetLabels,
        'target_segment': targetSegment,
        'target_filters': targetFilters,
        'target_count': targetCount,
        'sent_count': sentCount,
        'delivered_count': deliveredCount,
        'read_count': readCount,
        'failed_count': failedCount,
        'clicked_count': clickedCount,
        'status': status,
        'scheduled_at': scheduledAt,
        'started_at': startedAt,
        'completed_at': completedAt,
        'send_rate': sendRate,
        'created_by': createdBy,
        'created_at': createdAt,
      };

  Broadcast copyWith({
    int? id,
    String? broadcastId,
    String? name,
    String? messageType,
    String? message,
    String? templateName,
    dynamic templateParams,
    String? mediaUrl,
    dynamic buttons,
    String? targetType,
    dynamic targetLabels,
    String? targetSegment,
    dynamic targetFilters,
    int? targetCount,
    int? sentCount,
    int? deliveredCount,
    int? readCount,
    int? failedCount,
    int? clickedCount,
    String? status,
    String? scheduledAt,
    String? startedAt,
    String? completedAt,
    int? sendRate,
    String? createdBy,
    String? createdAt,
  }) {
    return Broadcast(
      id: id ?? this.id,
      broadcastId: broadcastId ?? this.broadcastId,
      name: name ?? this.name,
      messageType: messageType ?? this.messageType,
      message: message ?? this.message,
      templateName: templateName ?? this.templateName,
      templateParams: templateParams ?? this.templateParams,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      buttons: buttons ?? this.buttons,
      targetType: targetType ?? this.targetType,
      targetLabels: targetLabels ?? this.targetLabels,
      targetSegment: targetSegment ?? this.targetSegment,
      targetFilters: targetFilters ?? this.targetFilters,
      targetCount: targetCount ?? this.targetCount,
      sentCount: sentCount ?? this.sentCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      readCount: readCount ?? this.readCount,
      failedCount: failedCount ?? this.failedCount,
      clickedCount: clickedCount ?? this.clickedCount,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      sendRate: sendRate ?? this.sendRate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── Convenience ──
  bool get isDraft => status == 'draft';
  bool get isSending => status == 'sending';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  bool get isCancelled => status == 'cancelled';

  double get deliveryRate {
    if (sentCount == 0) return 0;
    return (deliveredCount / sentCount * 100).roundToDouble();
  }

  double get readRate {
    if (deliveredCount == 0) return 0;
    return (readCount / deliveredCount * 100).roundToDouble();
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
}