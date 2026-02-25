class Cart {
  final int? id;
  final String phone;
  final List<dynamic> items;
  final int itemCount;
  final double total;
  final String status;
  final int reminderCount;
  final String? lastReminderAt;
  final String? createdAt;
  final String? updatedAt;
  final String? convertedAt;

  const Cart({
    this.id,
    this.phone = '',
    this.items = const [],
    this.itemCount = 0,
    this.total = 0.0,
    this.status = 'active',
    this.reminderCount = 0,
    this.lastReminderAt,
    this.createdAt,
    this.updatedAt,
    this.convertedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] as int?,
      phone: json['phone'] as String? ?? '',
      items: json['items'] is List ? json['items'] : [],
      itemCount: _toInt(json['item_count']),
      total: _toDouble(json['total']),
      status: json['status'] as String? ?? 'active',
      reminderCount: _toInt(json['reminder_count']),
      lastReminderAt: json['last_reminder_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      convertedAt: json['converted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'items': items,
        'item_count': itemCount,
        'total': total,
        'status': status,
        'reminder_count': reminderCount,
        'last_reminder_at': lastReminderAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'converted_at': convertedAt,
      };

  Cart copyWith({
    int? id,
    String? phone,
    List<dynamic>? items,
    int? itemCount,
    double? total,
    String? status,
    int? reminderCount,
    String? lastReminderAt,
    String? createdAt,
    String? updatedAt,
    String? convertedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      total: total ?? this.total,
      status: status ?? this.status,
      reminderCount: reminderCount ?? this.reminderCount,
      lastReminderAt: lastReminderAt ?? this.lastReminderAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      convertedAt: convertedAt ?? this.convertedAt,
    );
  }

  bool get isActive => status == 'active';
  bool get isAbandoned => status == 'abandoned';
  bool get isConverted => status == 'converted';

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}