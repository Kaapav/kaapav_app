import 'package:flutter/material.dart';

import '../../services/api/api_client.dart';

class OwnerInboxScreen extends StatefulWidget {
  const OwnerInboxScreen({super.key});

  @override
  State<OwnerInboxScreen> createState() => _OwnerInboxScreenState();
}

class _OwnerInboxScreenState extends State<OwnerInboxScreen> {
  final List<String> _filters = const [
    'all',
    'order',
    'payment',
    'shipping',
    'unsupported',
  ];

  String _selectedType = 'all';
  bool _loading = true;
  int _unread = 0;
  String? _error;
  List<_OwnerAlert> _alerts = [];

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
          if (_selectedType != 'all') 'type': _selectedType,
        },
      );

      final data = Map<String, dynamic>.from(res.data as Map);
      final rawAlerts = (data['alerts'] as List? ?? []);

      setState(() {
        _alerts = rawAlerts
            .map((e) => _OwnerAlert.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _unread = _toInt(data['unread']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load Owner Inbox';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(_OwnerAlert alert) async {
    if (alert.isRead) return;

    try {
      await ApiClient.instance.dio.post('/owner-inbox/${alert.id}/read');

      setState(() {
        final index = _alerts.indexWhere((a) => a.id == alert.id);
        if (index >= 0) {
          _alerts[index] = _alerts[index].copyWith(isRead: true);
        }
        _unread = (_unread - 1).clamp(0, 999999).toInt();
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
    _markRead(alert);

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

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC49432);
    const bg = Color(0xFF0F0F10);
    const card = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            const Text('Owner Inbox'),
            if (_unread > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$_unread unread',
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
          if (_unread > 0)
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
          Expanded(
            child: _buildBody(card, gold),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Color card, Color gold) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return const Center(
        child: Text(
          'No owner alerts yet',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInbox,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        itemBuilder: (_, i) {
          final alert = _alerts[i];

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
                      Text(
                        _icon(alert.type),
                        style: const TextStyle(fontSize: 20),
                      ),
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
                          decoration: BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                          ),
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
                      if (alert.orderId.isNotEmpty)
                        _MiniPill(text: alert.orderId),
                      if (alert.amount > 0)
                        _MiniPill(text: _formatINR(alert.amount)),
                      if (alert.source.isNotEmpty)
                        _MiniPill(text: alert.source),
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
                          alert.actionLabel.isNotEmpty
                              ? alert.actionLabel
                              : 'Open',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: gold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _alerts.length,
      ),
    );
  }

  String _label(String type) {
    switch (type) {
      case 'order':
        return 'Orders';
      case 'payment':
        return 'Payments';
      case 'shipping':
        return 'Shipping';
      case 'unsupported':
        return 'Unsupported';
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
      case 'unsupported':
        return '⚠️';
      default:
        return '🔔';
    }
  }

  String _formatINR(num amount) {
    final value = amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
    return '₹$value';
  }
}

class _MiniPill extends StatelessWidget {
  final String text;

  const _MiniPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.07),
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

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}