class User {
  final int? id;
  final String userId;
  final String email;
  final String? name;
  final String role;
  final String? avatar;
  final bool isActive;
  final String? lastLogin;
  final String? createdAt;

  const User({
    this.id,
    this.userId = '',
    this.email = '',
    this.name,
    this.role = 'admin',
    this.avatar,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'admin',
      avatar: json['avatar'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      lastLogin: json['last_login'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'email': email,
        'name': name,
        'role': role,
        'avatar': avatar,
        'is_active': isActive ? 1 : 0,
        'last_login': lastLogin,
        'created_at': createdAt,
      };

  User copyWith({
    int? id,
    String? userId,
    String? email,
    String? name,
    String? role,
    String? avatar,
    bool? isActive,
    String? lastLogin,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}