// lib/screens/owner_inbox/owner_inbox_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/sms_alert_model.dart';
import '../../providers/sms_alert_provider.dart';
import '../../services/api/api_client.dart';

class OwnerInboxScreen extends ConsumerStatefulWidget {
  const OwnerInboxScreen({super.key});

  @override
  ConsumerState<OwnerInboxScreen> createState() => _OwnerInboxScreenState();
}

class _OwnerInboxScreenState extends ConsumerState<OwnerInboxScreen> {
  final List<String> _filters = const [
    'all',
    'otp',
    'payment',
    'shipping',
    'order',
    'system',
  ];

  String _selectedType = 'all';
  bool _loading = true;
  int _serverUnread = 0;
  String? _error;
  List<_OwnerAlert> _serverAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.instance.dio.get(
        '/owner-inbox',
        queryParameters: {
          'limit': 100,
          if (_selectedType != 'all' && _selectedType != 'otp') 'type': _selectedType,
        },
      );

      final data = Map<String, dynamic>.from(res.data as Map);
      final rawAlerts = (data['alerts'] as List? ?? []);

      setState(() {
        _serverAlerts = rawAlerts
            .map((e) => _OwnerAlert.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _serverUnread = _toInt(data['unread']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load server alerts';
        _loading = false;
      });
    }

    ref.read(smsAlertProvider.notifier).refresh();
  }

  Future<void> _markServerRead(_OwnerAlert alert) async {
    if (alert.isRead) return;

    try {
      await ApiClient.instance.dio.post('/owner-inbox/${alert.id}/read');

      setState(() {
        final index = _serverAlerts.indexWhere((a) => a.id == alert.id);
        if (index >= 0) {
          _serverAlerts[index] = _serverAlerts[index].copyWith(isRead: true);
        }
        _serverUnread = (_serverUnread - 1).clamp(0, 999999).toInt();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.dio.post('/owner-inbox/read-all');
      await _loadInbox();
    } catch (_) {}
  }

  void _openAction(_OwnerAlert alert) {
    _markServerRead(alert);

    if (alert.actionType == 'order_detail' && alert.orderId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/order-detail',
        arguments: {'orderId': alert.orderId},
      );
      return;
    }

    if (alert.actionType == 'chat' && alert.phone.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/chat-window',
        arguments: {'phone': alert.phone, 'name': alert.customerName},
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFC49432),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC49432);
    const bg = Color(0xFF0F0F10);
    const card = Color(0xFF1A1A1A);

    final smsState = ref.watch(smsAlertProvider);
    final totalUnread = _serverUnread + smsState.unreadCount;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            const Text('Owner Inbox'),
            if (totalUnread > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$totalUnread unread',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (totalUnread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Read all',
                style: TextStyle(color: gold),
              ),
            ),
          IconButton(
            onPressed: _loadInbox,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final type = _filters[i];
                final selected = type == _selectedType;

                return ChoiceChip(
                  selected: selected,
                  label: Text(_label(type)),
                  selectedColor: gold,
                  backgroundColor: card,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected ? gold : Colors.white12,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedType = type);
                    _loadInbox();
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _filters.length,
            ),
          ),

          // Permission Banner if SMS permission not granted
          if (!smsState.hasPermission)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sms_outlined, color: gold, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Enable SMS listener to auto-read Razorpay, Shiprocket & OTPs directly.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => ref.read(smsAlertProvider.notifier).requestPermission(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Enable'),
                  ),
                ],
              ),
            ),

          // Live Latest OTP Card (if available and viewing all or otp)
          if ((_selectedType == 'all' || _selectedType == 'otp') && smsState.latestOtp != null)
            _buildOtpBannerCard(smsState.latestOtp!, gold, card),

          Expanded(
            child: _buildCombinedAlertList(smsState, card, gold),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBannerCard(SmsAlert otpAlert, Color gold, Color card) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gold.withValues(alpha: 0.2),
            const Color(0xFF252525),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  otpAlert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${otpAlert.remainingTime.inMinutes}m left',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    otpAlert.otp ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _copyToClipboard(otpAlert.otp ?? '', 'OTP'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleWidget(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            otpAlert.body,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedAlertList(SmsAlertState smsState, Color card, Color gold) {
    if (_loading && _serverAlerts.isEmpty && smsState.alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter SMS alerts based on tab
    final filteredSms = smsState.alerts.where((s) {
      if (_selectedType == 'all') return true;
      if (_selectedType == 'otp') return s.type == 'otp';
      if (_selectedType == 'payment') return s.type == 'payment';
      if (_selectedType == 'shipping') return s.type == 'shipping';
      return false;
    }).toList();

    // Filter Server alerts based on tab
    final filteredServer = _serverAlerts.where((s) {
      if (_selectedType == 'all') return true;
      if (_selectedType == 'otp') return s.type == 'otp';
      if (_selectedType == 'payment') return s.type == 'payment';
      if (_selectedType == 'shipping') return s.type == 'shipping';
      if (_selectedType == 'order') return s.type == 'order';
      if (_selectedType == 'system') return s.type == 'system';
      return false;
    }).toList();

    final totalCount = filteredSms.length + filteredServer.length;

    if (totalCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _error != null ? Icons.cloud_off_outlined : Icons.inbox_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'No ${_label(_selectedType).toLowerCase()} alerts yet',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInbox,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        itemCount: filteredSms.length + filteredServer.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // Render SMS alerts first, then server alerts
          if (index < filteredSms.length) {
            final item = filteredSms[index];
            return _buildSmsAlertCard(item, card, gold);
          } else {
            final item = filteredServer[index - filteredSms.length];
            return _buildServerAlertCard(item, card, gold);
          }
        },
      ),
    );
  }

  Widget _buildSmsAlertCard(SmsAlert alert, Color card, Color gold) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: alert.isRead ? Colors.white10 : gold.withValues(alpha: .75),
        ),
        boxShadow: [
          if (!alert.isRead)
            BoxShadow(
              color: gold.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_icon(alert.type), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('SMS', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(text: _label(alert.type)),
              if (alert.sender.isNotEmpty) _MiniPill(text: alert.sender),
              if (alert.amount != null) _MiniPill(text: _formatINR(alert.amount!)),
              if (alert.referenceId != null) _MiniPill(text: alert.referenceId!),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (alert.otp != null)
                TextButton.icon(
                  onPressed: () => _copyToClipboard(alert.otp!, 'OTP'),
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('Copy OTP'),
                  style: TextButton.styleFrom(foregroundColor: gold),
                ),
              if (alert.trackingUrl != null)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(alert.trackingUrl!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.local_shipping, size: 15),
                  label: const Text('Track Shipment'),
                  style: TextButton.styleFrom(foregroundColor: gold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerAlertCard(_OwnerAlert alert, Color card, Color gold) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openAction(alert),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: alert.isRead ? Colors.white10 : gold.withValues(alpha: .75),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_icon(alert.type), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!alert.isRead)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alert.body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(text: _label(alert.type)),
                if (alert.orderId.isNotEmpty) _MiniPill(text: alert.orderId),
                if (alert.amount > 0) _MiniPill(text: _formatINR(alert.amount)),
                if (alert.source.isNotEmpty) _MiniPill(text: alert.source),
              ],
            ),
            if (alert.actionType.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openAction(alert),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(
                    alert.actionLabel.isNotEmpty ? alert.actionLabel : 'Open',
                  ),
                  style: TextButton.styleFrom(foregroundColor: gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _label(String type) {
    switch (type) {
      case 'order':
        return 'Orders';
      case 'payment':
        return 'Payments (Razorpay)';
      case 'shipping':
        return 'Shipping (Shiprocket)';
      case 'otp':
        return 'OTP & 2FA';
      case 'system':
        return 'System Alerts';
      default:
        return 'All';
    }
  }

  String _icon(String type) {
    switch (type) {
      case 'order':
        return '🛒';
      case 'payment':
        return '💰';
      case 'shipping':
        return '📦';
      case 'otp':
        return '🔑';
      case 'system':
        return '⚙️';
      default:
        return '🔔';
    }
  }

  String _formatINR(num amount) {
    final value = amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
    return '₹$value';
  }
}

class RoundedRectangleWidget extends RoundedRectangleBorder {
  const RoundedRectangleWidget({super.borderRadius});
}

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OwnerAlert {
  final int id;
  final String type;
  final String priority;
  final String title;
  final String body;
  final String orderId;
  final String phone;
  final String customerName;
  final double amount;
  final String source;
  final String actionType;
  final String actionLabel;
  final String actionUrl;
  final bool isRead;
  final String createdAt;

  const _OwnerAlert({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    required this.orderId,
    required this.phone,
    required this.customerName,
    required this.amount,
    required this.source,
    required this.actionType,
    required this.actionLabel,
    required this.actionUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory _OwnerAlert.fromJson(Map<String, dynamic> json) {
    return _OwnerAlert(
      id: _toInt(json['id']),
      type: '${json['type'] ?? 'system'}',
      priority: '${json['priority'] ?? 'normal'}',
      title: '${json['title'] ?? 'KAAPAV Alert'}',
      body: '${json['body'] ?? ''}',
      orderId: '${json['order_id'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      customerName: '${json['customer_name'] ?? ''}',
      amount: _toDouble(json['amount']),
      source: '${json['source'] ?? ''}',
      actionType: '${json['action_type'] ?? ''}',
      actionLabel: '${json['action_label'] ?? ''}',
      actionUrl: '${json['action_url'] ?? ''}',
      isRead: _toInt(json['is_read']) == 1,
      createdAt: '${json['created_at'] ?? ''}',
    );
  }

  _OwnerAlert copyWith({bool? isRead}) {
    return _OwnerAlert(
      id: id,
      type: type,
      priority: priority,
      title: title,
      body: body,
      orderId: orderId,
      phone: phone,
      customerName: customerName,
      amount: amount,
      source: source,
      actionType: actionType,
      actionLabel: actionLabel,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}