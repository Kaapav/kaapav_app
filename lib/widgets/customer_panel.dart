// lib/widgets/customer_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/customer.dart';
import '../models/chat.dart';
import '../models/order.dart';
import '../providers/chat_provider.dart';
import '../utils/formatters.dart';

class CustomerPanel extends ConsumerStatefulWidget {
  final Customer customer;
  final Chat? chat;
  final List<Order>? recentOrders;
  final VoidCallback? onClose;

  const CustomerPanel({
    super.key,
    required this.customer,
    this.chat,
    this.recentOrders,
    this.onClose,
  });

  @override
  ConsumerState<CustomerPanel> createState() => _CustomerPanelState();
}

class _CustomerPanelState extends ConsumerState<CustomerPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KaapavTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KaapavTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Contact'),
                  const SizedBox(height: 12),
                  _buildContactCard(),
                  const SizedBox(height: 20),
                  if (_hasAddress()) ...[
                    _buildSectionTitle('Address'),
                    const SizedBox(height: 12),
                    _buildAddressCard(),
                    const SizedBox(height: 20),
                  ],
                  if (widget.chat != null && widget.chat!.labels.isNotEmpty) ...[
                    _buildSectionTitle('Labels'),
                    const SizedBox(height: 12),
                    _buildLabels(),
                    const SizedBox(height: 20),
                  ],
                  if (widget.recentOrders != null && widget.recentOrders!.isNotEmpty) ...[
                    _buildSectionTitle('Recent Orders'),
                    const SizedBox(height: 12),
                    _buildRecentOrders(),
                    const SizedBox(height: 20),
                  ],
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAddress() {
    final c = widget.customer;
    return (c.address != null && c.address!.isNotEmpty) ||
        (c.city != null && c.city!.isNotEmpty);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KaapavTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [KaapavTheme.goldShadow],
            ),
            child: Center(
              child: Text(
                _getInitials(widget.customer.name.isNotEmpty ? widget.customer.name : widget.customer.phone),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.customer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: KaapavTheme.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.customer.tier == 'vip') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 12, color: Color(0xFFFFD700)),
                            SizedBox(width: 4),
                            Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD4A84B))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.customer.phone, style: const TextStyle(fontSize: 14, color: KaapavTheme.gray)),
                                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildBadge(widget.customer.segment.toUpperCase(), KaapavTheme.gold),
                    const SizedBox(width: 8),
                    _buildBadge(widget.customer.tier.toUpperCase(), _getTierColor(widget.customer.tier)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close), color: KaapavTheme.gray),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStat(Icons.shopping_bag, (widget.customer.orderCount).toString(), 'Orders', KaapavTheme.info),
        _buildStat(Icons.currency_rupee, Formatters.inr(widget.customer.totalSpent), 'Spent', KaapavTheme.success),
        _buildStat(Icons.chat_bubble, (widget.customer.messageCount).toString(), 'Messages', KaapavTheme.purple),
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: KaapavTheme.gray)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KaapavTheme.gray));
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: KaapavTheme.cream, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone, 'Phone', widget.customer.phone, () => _copy(widget.customer.phone)),
          if (widget.customer.email != null && widget.customer.email!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.email, 'Email', widget.customer.email!, () => _copy(widget.customer.email!)),
          ],
          const Divider(height: 24),
          _buildInfoRow(Icons.calendar_today, 'First contact', _fmtDate(widget.customer.firstSeen), null),
          const Divider(height: 24),
          _buildInfoRow(Icons.access_time, 'Last seen', _fmtDateTime(widget.customer.lastSeen), null),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: KaapavTheme.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: KaapavTheme.grayLight)),
                Text(value, style: const TextStyle(fontSize: 14, color: KaapavTheme.dark)),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.copy, size: 16, color: KaapavTheme.grayLight),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final c = widget.customer;
    final parts = <String>[];
    if (c.address != null && c.address!.isNotEmpty) parts.add(c.address!);
    if (c.city != null && c.city!.isNotEmpty) parts.add(c.city!);
    if (c.state != null && c.state!.isNotEmpty) parts.add(c.state!);
    if (c.pincode != null && c.pincode!.isNotEmpty) parts.add(c.pincode!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: KaapavTheme.cream, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, size: 18, color: KaapavTheme.gold),
          const SizedBox(width: 12),
          Expanded(child: Text(parts.join(', '), style: const TextStyle(fontSize: 14, color: KaapavTheme.dark, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildLabels() {
    final labels = widget.chat?.labels ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final color = KaapavTheme.labelColor(label);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        );
      }).toList(),
    );
  }

  Widget _buildRecentOrders() {
    final orders = widget.recentOrders ?? [];
    return Column(
      children: orders.take(3).map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: KaapavTheme.cream, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: KaapavTheme.orderStatusBg(order.status), borderRadius: BorderRadius.circular(8)),
                child: Icon(KaapavTheme.orderStatusIcon(order.status), size: 18, color: KaapavTheme.orderStatusText(order.status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KaapavTheme.dark)),
                    Text('${order.itemCount} items • ${Formatters.inr(order.total)}', style: const TextStyle(fontSize: 12, color: KaapavTheme.gray)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: KaapavTheme.orderStatusBg(order.status), borderRadius: BorderRadius.circular(4)),
                child: Text(order.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: KaapavTheme.orderStatusText(order.status))),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    final botEnabled = widget.chat?.isBotEnabled ?? true;
    return Column(
      children: [
        _buildActionBtn(botEnabled ? Icons.smart_toy : Icons.smart_toy_outlined, botEnabled ? 'Disable Bot' : 'Enable Bot', KaapavTheme.gold, () {
          if (widget.chat != null) ref.read(chatProvider.notifier).toggleBot(widget.chat!.phone);
        }),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
  }

  Color _getTierColor(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'gold': return const Color(0xFFFFD700);
      case 'silver': return const Color(0xFFC0C0C0);
      default: return const Color(0xFFCD7F32);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String _fmtDate(String? s) {
    if (s == null || s.isEmpty) return 'Unknown';
    final dt = Formatters.parseDate(s);
    return dt != null ? Formatters.date(dt) : 'Unknown';
  }

  String _fmtDateTime(String? s) {
    if (s == null || s.isEmpty) return 'Unknown';
    final dt = Formatters.parseDate(s);
    return dt != null ? Formatters.dateTime(dt) : 'Unknown';
  }
}