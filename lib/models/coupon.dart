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
      usageLimit: json['usage_limit'] == null
    ? null
    : _toInt(json['usage_limit']),
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

  static const _unset = Object();

Coupon copyWith({
  int? id,
  String? code,
  String? type,
  double? value,
  Object? minOrder = _unset,
  Object? maxDiscount = _unset,
  Object? usageLimit = _unset,
  int? usedCount,
  Object? startsAt = _unset,
  Object? expiresAt = _unset,
  bool? isActive,
  Object? createdAt = _unset,
}) {
  return Coupon(
    id: id ?? this.id,
    code: code ?? this.code,
    type: type ?? this.type,
    value: value ?? this.value,
    minOrder: identical(minOrder, _unset)
        ? this.minOrder
        : minOrder as double?,
    maxDiscount: identical(maxDiscount, _unset)
        ? this.maxDiscount
        : maxDiscount as double?,
    usageLimit: identical(usageLimit, _unset)
        ? this.usageLimit
        : usageLimit as int?,
    usedCount: usedCount ?? this.usedCount,
    startsAt: identical(startsAt, _unset)
        ? this.startsAt
        : startsAt as String?,
    expiresAt: identical(expiresAt, _unset)
        ? this.expiresAt
        : expiresAt as String?,
    isActive: isActive ?? this.isActive,
    createdAt: identical(createdAt, _unset)
        ? this.createdAt
        : createdAt as String?,
  );
}

  bool get isPercent => type == 'percent';
  bool get isFixed => type == 'fixed';
bool get hasUsageLeft =>
    usageLimit == null ||
    usageLimit! <= 0 ||
    usedCount < usageLimit!;

bool get hasStarted {
  if (startsAt == null || startsAt!.trim().isEmpty) return true;

  try {
    return !DateTime.parse(startsAt!)
        .toLocal()
        .isAfter(DateTime.now());
  } catch (_) {
    return false;
  }
}

bool get isExpired {
  if (expiresAt == null || expiresAt!.trim().isEmpty) return false;

  try {
    return DateTime.parse(expiresAt!)
        .toLocal()
        .isBefore(DateTime.now());
  } catch (_) {
    return true;
  }
}

bool get isScheduled => isActive && !hasStarted;

bool get isExhausted => isActive && !hasUsageLeft;

bool get isValid =>
    isActive &&
    hasStarted &&
    hasUsageLeft &&
    !isExpired;

String get statusLabel {
  if (!isActive) return 'Disabled';
  if (!hasStarted) return 'Scheduled';
  if (isExpired) return 'Expired';
  if (!hasUsageLeft) return 'Exhausted';
  return 'Live';
}

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