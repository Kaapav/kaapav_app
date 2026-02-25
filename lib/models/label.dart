class Label {
  final int? id;
  final String name;
  final String color;
  final String? description;
  final int customerCount;
  final int chatCount;
  final bool isActive;
  final String? createdAt;

  const Label({
    this.id,
    this.name = '',
    this.color = '#C49432',
    this.description,
    this.customerCount = 0,
    this.chatCount = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#C49432',
      description: json['description'] as String?,
      customerCount: _toInt(json['customer_count']),
      chatCount: _toInt(json['chat_count']),
      isActive: json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'description': description,
        'customer_count': customerCount,
        'chat_count': chatCount,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  Label copyWith({
    int? id,
    String? name,
    String? color,
    String? description,
    int? customerCount,
    int? chatCount,
    bool? isActive,
    String? createdAt,
  }) {
    return Label(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      customerCount: customerCount ?? this.customerCount,
      chatCount: chatCount ?? this.chatCount,
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