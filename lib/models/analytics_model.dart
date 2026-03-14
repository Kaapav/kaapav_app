// lib/models/analytics_model.dart

import 'package:flutter/material.dart';

/// Matches exactly what /api/stats returns:
/// { totalChats, unreadMessages, totalOrders, pendingOrders,
///   totalCustomers, totalProducts, totalRevenue }
class DashboardStats {
  final int totalChats;       // from 'totalChats'
  final int unreadMessages;   // from 'unreadMessages'
  final int totalOrders;      // from 'totalOrders'
  final int pendingOrders;    // from 'pendingOrders'
  final int totalCustomers;   // from 'totalCustomers'
  final int totalProducts;    // from 'totalProducts'
  final double totalRevenue;  // from 'totalRevenue'

  // Derived / defaulted — API doesn't return these
  final int activeChats;      // = totalChats (same thing)
  final double todayRevenue;  // not in API → default 0
  final int todayOrders;      // not in API → default 0
  final double inventoryValue;// not in API → default 0

  const DashboardStats({
    required this.totalChats,
    required this.unreadMessages,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalCustomers,
    required this.totalProducts,
    required this.totalRevenue,
    this.activeChats = 0,
    this.todayRevenue = 0,
    this.todayOrders = 0,
    this.inventoryValue = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final totalChats = (json['totalChats'] as num?)?.toInt() ?? 0;
    return DashboardStats(
      totalChats:     totalChats,
      unreadMessages: (json['unreadMessages'] as num?)?.toInt() ?? 0,
      totalOrders:    (json['totalOrders']    as num?)?.toInt() ?? 0,
      pendingOrders:  (json['pendingOrders']  as num?)?.toInt() ?? 0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalProducts:  (json['totalProducts']  as num?)?.toInt() ?? 0,
      totalRevenue:   (json['totalRevenue']   as num?)?.toDouble() ?? 0.0,
      // Derived
      activeChats:    totalChats,
      todayRevenue:   (json['todayRevenue']   as num?)?.toDouble() ?? 0.0,
      todayOrders:    (json['todayOrders']    as num?)?.toInt() ?? 0,
      inventoryValue: (json['inventoryValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalChats':     totalChats,
    'unreadMessages': unreadMessages,
    'totalOrders':    totalOrders,
    'pendingOrders':  pendingOrders,
    'totalCustomers': totalCustomers,
    'totalProducts':  totalProducts,
    'totalRevenue':   totalRevenue,
    'activeChats':    activeChats,
    'todayRevenue':   todayRevenue,
    'todayOrders':    todayOrders,
    'inventoryValue': inventoryValue,
  };

  DashboardStats copyWith({
    int? totalChats,
    int? unreadMessages,
    int? totalOrders,
    int? pendingOrders,
    int? totalCustomers,
    int? totalProducts,
    double? totalRevenue,
    int? activeChats,
    double? todayRevenue,
    int? todayOrders,
    double? inventoryValue,
  }) {
    return DashboardStats(
      totalChats:     totalChats     ?? this.totalChats,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      totalOrders:    totalOrders    ?? this.totalOrders,
      pendingOrders:  pendingOrders  ?? this.pendingOrders,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalProducts:  totalProducts  ?? this.totalProducts,
      totalRevenue:   totalRevenue   ?? this.totalRevenue,
      activeChats:    activeChats    ?? this.activeChats,
      todayRevenue:   todayRevenue   ?? this.todayRevenue,
      todayOrders:    todayOrders    ?? this.todayOrders,
      inventoryValue: inventoryValue ?? this.inventoryValue,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Matches what /api/analytics/activities returns:
/// { phone, text, direction, timestamp }
/// NOTE: id, type, title, description, orderId are NOT in API
///       We derive them from what IS available.
class Activity {
  final String id;           // generated from timestamp+phone
  final String? type;        // derived from direction
  final String? phone;       // from 'phone'
  final String? orderId;     // not in API → null
  final String? title;       // derived from phone/text
  final String? description; // from 'text'
  final String? timestamp;   // from 'timestamp'
  final String? direction;   // from 'direction' (incoming/outgoing)

  const Activity({
    required this.id,
    this.type,
    this.phone,
    this.orderId,
    this.title,
    this.description,
    this.timestamp,
    this.direction,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    final phone     = json['phone']?.toString();
    final text      = json['text']?.toString();
    final direction = json['direction']?.toString();
    final timestamp = json['timestamp']?.toString();

    // Derive type from direction
    final type = direction == 'incoming' ? 'message' : 'outgoing';

    // Generate a stable ID from timestamp + phone
    final id = '${timestamp ?? ''}_${phone ?? ''}'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

    return Activity(
      id:          id.isNotEmpty ? id : 'act_${DateTime.now().millisecondsSinceEpoch}',
      type:        type,
      phone:       phone,
      orderId:     json['orderId']?.toString(),
      title:       phone ?? 'Unknown',
      description: text,
      timestamp:   timestamp,
      direction:   direction,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'type':        type,
    'phone':       phone,
    'orderId':     orderId,
    'title':       title,
    'description': description,
    'timestamp':   timestamp,
    'direction':   direction,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

/// /api/analytics/pending returns a LIST of pending orders — not counts.
/// We parse that list and compute the counts ourselves.
class PendingActions {
  final int total;
  final int pendingConfirmations; // status == 'pending'
  final int pendingPayments;      // payment_status == 'unpaid'
  final int pendingShipments;     // status == 'confirmed' or 'processing'
  final int abandonedCarts;       // always 0 — not tracked in API

  const PendingActions({
    required this.total,
    required this.pendingConfirmations,
    required this.pendingPayments,
    required this.pendingShipments,
    required this.abandonedCarts,
  });

  /// Build from the raw orders array returned by /api/analytics/pending
  factory PendingActions.fromOrdersList(List<dynamic> orders) {
    int confirmations = 0;
    int payments = 0;
    int shipments = 0;

    for (final o in orders) {
      final status        = o['status']?.toString() ?? '';
      final paymentStatus = o['payment_status']?.toString() ?? '';

      if (status == 'pending') confirmations++;
      if (paymentStatus == 'unpaid') payments++;
      if (status == 'confirmed' || status == 'processing') shipments++;
    }

    return PendingActions(
      total:                orders.length,
      pendingConfirmations: confirmations,
      pendingPayments:      payments,
      pendingShipments:     shipments,
      abandonedCarts:       0,
    );
  }

  /// Fallback: if somehow we get a JSON object (future-proofing)
  factory PendingActions.fromJson(Map<String, dynamic> json) {
    return PendingActions(
      total:                (json['total']                as num?)?.toInt() ?? 0,
      pendingConfirmations: (json['pendingConfirmations'] as num?)?.toInt() ?? 0,
      pendingPayments:      (json['pendingPayments']      as num?)?.toInt() ?? 0,
      pendingShipments:     (json['pendingShipments']     as num?)?.toInt() ?? 0,
      abandonedCarts:       (json['abandonedCarts']       as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total':                total,
    'pendingConfirmations': pendingConfirmations,
    'pendingPayments':      pendingPayments,
    'pendingShipments':     pendingShipments,
    'abandonedCarts':       abandonedCarts,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

/// Helper config used by activity tiles in dashboard
class ActivityConfig {
  final IconData icon;
  final Color color;
  const ActivityConfig(this.icon, this.color);
}