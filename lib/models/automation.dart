class Automation {
  final int? id;
  final String name;
  final String? description;
  final String? triggerType;
  final dynamic triggerConditions;
  final List<dynamic> actions;
  final int delayMinutes;
  final int triggeredCount;
  final String? lastTriggeredAt;
  final bool isActive;
  final String? createdAt;

  const Automation({
    this.id,
    this.name = '',
    this.description,
    this.triggerType,
    this.triggerConditions,
    this.actions = const [],
    this.delayMinutes = 0,
    this.triggeredCount = 0,
    this.lastTriggeredAt,
    this.isActive = true,
    this.createdAt,
  });

  factory Automation.fromJson(Map<String, dynamic> json) {
    return Automation(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      triggerType: json['trigger_type'] as String?,
      triggerConditions: json['trigger_conditions'],
      actions: json['actions'] is List ? json['actions'] : [],
      delayMinutes: _toInt(json['delay_minutes']),
      triggeredCount: _toInt(json['triggered_count']),
      lastTriggeredAt: json['last_triggered_at'] as String?,
      isActive: json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'trigger_type': triggerType,
        'trigger_conditions': triggerConditions,
        'actions': actions,
        'delay_minutes': delayMinutes,
        'triggered_count': triggeredCount,
        'last_triggered_at': lastTriggeredAt,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  Automation copyWith({
    int? id,
    String? name,
    String? description,
    String? triggerType,
    dynamic triggerConditions,
    List<dynamic>? actions,
    int? delayMinutes,
    int? triggeredCount,
    String? lastTriggeredAt,
    bool? isActive,
    String? createdAt,
  }) {
    return Automation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      triggerType: triggerType ?? this.triggerType,
      triggerConditions: triggerConditions ?? this.triggerConditions,
      actions: actions ?? this.actions,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      triggeredCount: triggeredCount ?? this.triggeredCount,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
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
}