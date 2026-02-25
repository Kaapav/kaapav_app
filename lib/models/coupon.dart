class Coupon {
  final int? id;
  final String code;
  final String type;
  final double value;
  final double? minOrder;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final String? startsAt;
  final String? expiresAt;
  final bool isActive;
  final String? createdAt;

  const Coupon({
    this.id,
    this.code = '',
    this.type = 'percent',
    this.value = 0.0,
    this.minOrder,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    this.startsAt,
    this.expiresAt,
    this.isActive = true,
    this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'percent',
      value: _toDouble(json['value']),
      minOrder:
          json['min_order'] != null ? _toDouble(json['min_order']) : null,
      maxDiscount: json['max_discount'] != null
          ? _toDouble(json['max_discount'])
          : null,
      usageLimit: json['usage_limit'] as int?,
      usedCount: _toInt(json['used_count']),
      startsAt: json['starts_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      isActive: json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'type': type,
        'value': value,
        'min_order': minOrder,
        'max_discount': maxDiscount,
        'usage_limit': usageLimit,
        'used_count': usedCount,
        'starts_at': startsAt,
        'expires_at': expiresAt,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  Coupon copyWith({
    int? id,
    String? code,
    String? type,
    double? value,
    double? minOrder,
    double? maxDiscount,
    int? usageLimit,
    int? usedCount,
    String? startsAt,
    String? expiresAt,
    bool? isActive,
    String? createdAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrder: minOrder ?? this.minOrder,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPercent => type == 'percent';
  bool get isFixed => type == 'fixed';
  bool get hasUsageLeft =>
      usageLimit == null || usedCount < usageLimit!;

  bool get isExpired {
    if (expiresAt == null) return false;
    try {
      return DateTime.parse(expiresAt!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool get isValid => isActive && hasUsageLeft && !isExpired;

  String get displayValue {
    if (isPercent) return '${value.toStringAsFixed(0)}%';
    return '₹${value.toStringAsFixed(0)}';
  }

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