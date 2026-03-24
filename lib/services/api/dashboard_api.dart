import '../../models/analytics_model.dart';
import 'api_client.dart';

class DashboardApi {
  final ApiClient _client;
  DashboardApi(this._client);

  // ── /api/stats ─────────────────────────────────────────────────
  Future<DashboardStats> getStats() async {
    final response = await _client.get('/api/stats');
    final Map<String, dynamic> body = _toMap(response);
    final Map<String, dynamic> stats =
        (body['stats'] as Map<String, dynamic>?) ?? {};
    return DashboardStats.fromJson(stats);
  }

  // ── /api/analytics/activities ──────────────────────────────────
  Future<List<Activity>> getActivities() async {
    final response = await _client.get('/api/analytics/activities');
    final Map<String, dynamic> body = _toMap(response);
    final List<dynamic> raw =
        (body['activities'] as List<dynamic>?) ?? [];

    return raw
        .map((e) => Activity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── /api/analytics/pending ─────────────────────────────────────
  Future<PendingActions> getPending() async {
    final response = await _client.get('/api/analytics/pending');
    final Map<String, dynamic> body = _toMap(response);
    final List<dynamic> raw =
        (body['pending'] as List<dynamic>?) ?? [];
    return PendingActions.fromOrdersList(raw);
  }

  // ── /api/dashboard/ops ─────────────────────────────────────────
  Future<DashboardOpsData> getOps() async {
    final response = await _client.get('/api/dashboard/ops');
    final Map<String, dynamic> body = _toMap(response);
    final Map<String, dynamic> ops =
        (body['ops'] as Map<String, dynamic>?) ?? {};
    return DashboardOpsData.fromJson(ops);
  }

  // ── Helper ─────────────────────────────────────────────────────
  Map<String, dynamic> _toMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;

    try {
      final data = (response as dynamic).data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}

    return {};
  }
}

// ═══════════════════════════════════════════════════════════════
// OPS MODELS
// ═══════════════════════════════════════════════════════════════

class DashboardOpsData {
  final PaymentBreakdown paymentBreakdown;
  final ShipmentQueue shipmentQueue;
  final InventoryAlerts inventory;
  final SourceBreakdown sourceBreakdown;
  final SyncHealth syncHealth;
  final TodayOpsSummary todayOps;
  final String? lastSyncAt;

  const DashboardOpsData({
    required this.paymentBreakdown,
    required this.shipmentQueue,
    required this.inventory,
    required this.sourceBreakdown,
    required this.syncHealth,
    required this.todayOps,
    this.lastSyncAt,
  });

  factory DashboardOpsData.fromJson(Map<String, dynamic> json) {
    return DashboardOpsData(
      paymentBreakdown: PaymentBreakdown.fromJson(
        _asMap(json['paymentBreakdown']),
      ),
      shipmentQueue: ShipmentQueue.fromJson(
        _asMap(json['shipmentQueue']),
      ),
      inventory: InventoryAlerts.fromJson(
        _asMap(json['inventory']),
      ),
      sourceBreakdown: SourceBreakdown.fromJson(
        _asMap(json['sourceBreakdown']),
      ),
      syncHealth: SyncHealth.fromJson(
        _asMap(json['syncHealth']),
      ),
      todayOps: TodayOpsSummary.fromJson(
        _asMap(json['todayOps']),
      ),
      lastSyncAt: json['lastSyncAt']?.toString(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }
}

class PaymentBreakdown {
  final int paidCount;
  final int unpaidCount;
  final double paidValue;
  final double unpaidValue;
  final double todayPaid;
  final double todayUnpaid;

  const PaymentBreakdown({
    this.paidCount = 0,
    this.unpaidCount = 0,
    this.paidValue = 0,
    this.unpaidValue = 0,
    this.todayPaid = 0,
    this.todayUnpaid = 0,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      paidCount: _toInt(json['paidCount']),
      unpaidCount: _toInt(json['unpaidCount']),
      paidValue: _toDouble(json['paidValue']),
      unpaidValue: _toDouble(json['unpaidValue']),
      todayPaid: _toDouble(json['todayPaid']),
      todayUnpaid: _toDouble(json['todayUnpaid']),
    );
  }
}

class ShipmentQueue {
  final int readyForShiprocket;
  final int shiprocketBooked;
  final int awbAdded;

  const ShipmentQueue({
    this.readyForShiprocket = 0,
    this.shiprocketBooked = 0,
    this.awbAdded = 0,
  });

  factory ShipmentQueue.fromJson(Map<String, dynamic> json) {
    return ShipmentQueue(
      readyForShiprocket: _toInt(json['readyForShiprocket']),
      shiprocketBooked: _toInt(json['shiprocketBooked']),
      awbAdded: _toInt(json['awbAdded']),
    );
  }
}

class InventoryAlerts {
  final int lowStockCount;
  final int outOfStockCount;
  final int totalProducts;

  const InventoryAlerts({
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalProducts = 0,
  });

  factory InventoryAlerts.fromJson(Map<String, dynamic> json) {
    return InventoryAlerts(
      lowStockCount: _toInt(json['lowStockCount']),
      outOfStockCount: _toInt(json['outOfStockCount']),
      totalProducts: _toInt(json['totalProducts']),
    );
  }
}

class SourceBreakdown {
  final int whatsapp;
  final int catalogue;
  final int website;
  final int manual;

  const SourceBreakdown({
    this.whatsapp = 0,
    this.catalogue = 0,
    this.website = 0,
    this.manual = 0,
  });

  factory SourceBreakdown.fromJson(Map<String, dynamic> json) {
    return SourceBreakdown(
      whatsapp: _toInt(json['whatsapp']),
      catalogue: _toInt(json['catalogue']),
      website: _toInt(json['website']),
      manual: _toInt(json['manual']),
    );
  }
}

class SyncHealth {
  final bool d1Live;
  final bool googleSheetsConnected;
  final bool supabaseConnected;
  final int pendingQueue;
  final int failedQueue;
  final String mode;
  final String? lastSuccess;
  final String? lastFailure;

  const SyncHealth({
    this.d1Live = true,
    this.googleSheetsConnected = false,
    this.supabaseConnected = false,
    this.pendingQueue = 0,
    this.failedQueue = 0,
    this.mode = 'd1_only',
    this.lastSuccess,
    this.lastFailure,
  });

  factory SyncHealth.fromJson(Map<String, dynamic> json) {
    return SyncHealth(
      d1Live: _toBool(json['d1Live'], fallback: true),
      googleSheetsConnected: _toBool(json['googleSheetsConnected']),
      supabaseConnected: _toBool(json['supabaseConnected']),
      pendingQueue: _toInt(json['pendingQueue']),
      failedQueue: _toInt(json['failedQueue']),
      mode: json['mode']?.toString() ?? 'd1_only',
      lastSuccess: json['lastSuccess']?.toString(),
      lastFailure: json['lastFailure']?.toString(),
    );
  }
}

class TodayOpsSummary {
  final int totalOrders;
  final int paidOrders;
  final int unpaidOrders;
  final int readyToShip;
  final int shippedToday;

  const TodayOpsSummary({
    this.totalOrders = 0,
    this.paidOrders = 0,
    this.unpaidOrders = 0,
    this.readyToShip = 0,
    this.shippedToday = 0,
  });

  factory TodayOpsSummary.fromJson(Map<String, dynamic> json) {
    return TodayOpsSummary(
      totalOrders: _toInt(json['totalOrders']),
      paidOrders: _toInt(json['paidOrders']),
      unpaidOrders: _toInt(json['unpaidOrders']),
      readyToShip: _toInt(json['readyToShip']),
      shippedToday: _toInt(json['shippedToday']),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SAFE PARSERS
// ═══════════════════════════════════════════════════════════════

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  final raw = value?.toString().toLowerCase();
  if (raw == 'true' || raw == '1') return true;
  if (raw == 'false' || raw == '0') return false;
  return fallback;
}