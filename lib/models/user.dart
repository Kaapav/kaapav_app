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

// ════════════════════════════════════════════════════════════════
// ADD THIS CLASS BELOW (Dashboard Statistics Model)
// ════════════════════════════════════════════════════════════════

class DashboardStats {
  final int totalChats;
  final int activeChats;
  final int totalMessages;
  final int unreadMessages;
  final int totalOrders;
  final int pendingOrders;
  final double totalRevenue;
  final int totalProducts;
  final int totalCustomers;

  const DashboardStats({
    this.totalChats = 0,
    this.activeChats = 0,
    this.totalMessages = 0,
    this.unreadMessages = 0,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.totalRevenue = 0.0,
    this.totalProducts = 0,
    this.totalCustomers = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalChats: json['total_chats'] as int? ?? 0,
      activeChats: json['active_chats'] as int? ?? 0,
      totalMessages: json['total_messages'] as int? ?? 0,
      unreadMessages: json['unread_messages'] as int? ?? 
                      json['unread_chats'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      pendingOrders: json['pending_orders'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalProducts: json['total_products'] as int? ?? 0,
      totalCustomers: json['total_customers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_chats': totalChats,
        'active_chats': activeChats,
        'total_messages': totalMessages,
        'unread_messages': unreadMessages,
        'total_orders': totalOrders,
        'pending_orders': pendingOrders,
        'total_revenue': totalRevenue,
        'total_products': totalProducts,
        'total_customers': totalCustomers,
      };

  DashboardStats copyWith({
    int? totalChats,
    int? activeChats,
    int? totalMessages,
    int? unreadMessages,
    int? totalOrders,
    int? pendingOrders,
    double? totalRevenue,
    int? totalProducts,
    int? totalCustomers,
  }) {
    return DashboardStats(
      totalChats: totalChats ?? this.totalChats,
      activeChats: activeChats ?? this.activeChats,
      totalMessages: totalMessages ?? this.totalMessages,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      totalOrders: totalOrders ?? this.totalOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalProducts: totalProducts ?? this.totalProducts,
      totalCustomers: totalCustomers ?? this.totalCustomers,
    );
  }
}