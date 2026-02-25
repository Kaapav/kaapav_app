// lib/models/analytics_model.dart

import 'package:flutter/material.dart';

class DashboardStats {
  final int activeChats;
  final double todayRevenue;
  final int todayOrders;
  final int totalCustomers;

  DashboardStats({
    required this.activeChats,
    required this.todayRevenue,
    required this.todayOrders,
    required this.totalCustomers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeChats: json['activeChats'] ?? 0,
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      todayOrders: json['todayOrders'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeChats': activeChats,
      'todayRevenue': todayRevenue,
      'todayOrders': todayOrders,
      'totalCustomers': totalCustomers,
    };
  }
}

class Activity {
  final String id;
  final String? type;
  final String? phone;
  final String? orderId;
  final String? title;
  final String? description;
  final String? timestamp;

  Activity({
    required this.id,
    this.type,
    this.phone,
    this.orderId,
    this.title,
    this.description,
    this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      type: json['type'],
      phone: json['phone'],
      orderId: json['orderId'],
      title: json['title'],
      description: json['description'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'phone': phone,
      'orderId': orderId,
      'title': title,
      'description': description,
      'timestamp': timestamp,
    };
  }
}

class PendingActions {
  final int total;
  final int pendingConfirmations;
  final int pendingPayments;
  final int pendingShipments;
  final int abandonedCarts;

  PendingActions({
    required this.total,
    required this.pendingConfirmations,
    required this.pendingPayments,
    required this.pendingShipments,
    required this.abandonedCarts,
  });

  factory PendingActions.fromJson(Map<String, dynamic> json) {
    return PendingActions(
      total: json['total'] ?? 0,
      pendingConfirmations: json['pendingConfirmations'] ?? 0,
      pendingPayments: json['pendingPayments'] ?? 0,
      pendingShipments: json['pendingShipments'] ?? 0,
      abandonedCarts: json['abandonedCarts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pendingConfirmations': pendingConfirmations,
      'pendingPayments': pendingPayments,
      'pendingShipments': pendingShipments,
      'abandonedCarts': abandonedCarts,
    };
  }
}

class ActivityConfig {
  final IconData icon;
  final Color color;

  ActivityConfig(this.icon, this.color);
}