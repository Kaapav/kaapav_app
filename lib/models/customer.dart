class Customer {
  final int? id;
  final String phone;
  final String name;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String segment;
  final String tier;
  final List<String> labels;
  final int messageCount;
  final int orderCount;
  final double totalSpent;
  final List<dynamic> cart;
  final String? cartUpdatedAt;
  final String? language;
  final bool optedIn;
  final String? firstSeen;
  final String? lastSeen;
  final String? lastOrderAt;
  final String? pushSubscription;
  final String? createdAt;
  final String? updatedAt;

  const Customer({
    this.id,
    this.phone = '',
    this.name = '',
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.segment = 'new',
    this.tier = 'bronze',
    this.labels = const [],
    this.messageCount = 0,
    this.orderCount = 0,
    this.totalSpent = 0.0,
    this.cart = const [],
    this.cartUpdatedAt,
    this.language,
    this.optedIn = true,
    this.firstSeen,
    this.lastSeen,
    this.lastOrderAt,
    this.pushSubscription,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int?,
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      segment: json['segment'] as String? ?? 'new',
      tier: json['tier'] as String? ?? 'bronze',
      labels: _parseList(json['labels']),
      messageCount: _toInt(json['message_count']),
      orderCount: _toInt(json['order_count']),
      totalSpent: _toDouble(json['total_spent']),
      cart: _parseDynamicList(json['cart']),
      cartUpdatedAt: json['cart_updated_at'] as String?,
      language: json['language'] as String?,
      optedIn: json['opted_in'] == 1 ||
          json['opted_in'] == true ||
          json['opted_in'] == null,
      firstSeen: json['first_seen'] as String?,
      lastSeen: json['last_seen'] as String?,
      lastOrderAt: json['last_order_at'] as String?,
      pushSubscription: json['push_subscription'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'segment': segment,
        'tier': tier,
        'labels': labels,
        'message_count': messageCount,
        'order_count': orderCount,
        'total_spent': totalSpent,
        'cart': cart,
        'cart_updated_at': cartUpdatedAt,
        'language': language,
        'opted_in': optedIn ? 1 : 0,
        'first_seen': firstSeen,
        'last_seen': lastSeen,
        'last_order_at': lastOrderAt,
        'push_subscription': pushSubscription,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Customer copyWith({
    int? id,
    String? phone,
    String? name,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? segment,
    String? tier,
    List<String>? labels,
    int? messageCount,
    int? orderCount,
    double? totalSpent,
    List<dynamic>? cart,
    String? cartUpdatedAt,
    String? language,
    bool? optedIn,
    String? firstSeen,
    String? lastSeen,
    String? lastOrderAt,
    String? pushSubscription,
    String? createdAt,
    String? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      segment: segment ?? this.segment,
      tier: tier ?? this.tier,
      labels: labels ?? this.labels,
      messageCount: messageCount ?? this.messageCount,
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
      cart: cart ?? this.cart,
      cartUpdatedAt: cartUpdatedAt ?? this.cartUpdatedAt,
      language: language ?? this.language,
      optedIn: optedIn ?? this.optedIn,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      lastOrderAt: lastOrderAt ?? this.lastOrderAt,
      pushSubscription: pushSubscription ?? this.pushSubscription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Convenience getters ──
  bool get isVIP => segment == 'vip' || tier == 'gold';
  bool get hasCart => cart.isNotEmpty;
  String get displayName => name.isNotEmpty ? name : phone;
  String get tierEmoji {
    switch (tier) {
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      default:
        return '🥉';
    }
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

  static List<String> _parseList(dynamic val) {
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

  static List<dynamic> _parseDynamicList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val;
    return [];
  }
}