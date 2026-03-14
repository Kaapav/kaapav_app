// lib/screens/orders/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../providers/order_provider.dart';
import '../../widgets/toast.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {

  @override
  void initState() {
    super.initState();
    final orders = ref.read(orderProvider).orders;
    if (orders.isEmpty) {
      Future.microtask(() => ref.read(orderProvider.notifier).loadOrders());
    }
  }

  // ── Status options in order ─────────────────────────────────
  static const _statuses = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  static const _statusColors = {
    'pending':    Color(0xFFF59E0B),
    'confirmed':  Color(0xFF3B82F6),
    'processing': Color(0xFF8B5CF6),
    'shipped':    Color(0xFF06B6D4),
    'delivered':  Color(0xFF10B981),
    'cancelled':  Color(0xFFEF4444),
  };

  static const _statusEmojis = {
    'pending':    '⏳',
    'confirmed':  '✅',
    'processing': '📦',
    'shipped':    '🚚',
    'delivered':  '🎉',
    'cancelled':  '❌',
  };

  bool _isUpdatingStatus = false;

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final ok = await ref.read(orderProvider.notifier).updateOrderStatus(
        widget.orderId, newStatus,
      );
      if (!mounted) return;
      if (ok) {
        KaapavToast.success(context, 'Status updated to $newStatus');
      } else {
        KaapavToast.error(context, 'Failed to update status');
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _confirmOrder() async {
    final ok = await ref.read(orderProvider.notifier).confirmOrder(widget.orderId);
    if (!mounted) return;
    if (ok) KaapavToast.success(context, 'Order confirmed');
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('This cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref.read(orderProvider.notifier).cancelOrder(widget.orderId);
    if (!mounted) return;
    if (ok) KaapavToast.warning(context, 'Order cancelled');
  }

  Future<void> _generatePaymentLink() async {
    final link = await ref.read(orderProvider.notifier).generatePaymentLink(widget.orderId);
    if (!mounted) return;
    if (link != null) KaapavToast.success(context, 'Payment link generated & sent on WhatsApp');
  }

  void _showStatusPicker(BuildContext context, String currentStatus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Update Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ..._statuses.map((status) {
              final isCurrent = status == currentStatus;
              final color = _statusColors[status] ?? KaapavTheme.gold;
              return ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(_statusEmojis[status] ?? '•', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                title: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? color : null,
                  ),
                ),
                trailing: isCurrent
                    ? Icon(Icons.check_circle_rounded, color: color, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isCurrent) _changeStatus(status);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider).orders
        .where((o) => o.orderId == widget.orderId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.orderId)),
        body: const Center(child: CircularProgressIndicator(color: KaapavTheme.gold)),
      );
    }

    final statusColor = _statusColors[order.status] ?? KaapavTheme.gold;
    final statusEmoji = _statusEmojis[order.status] ?? '📋';

    // Parse items from order
    final List<Map<String, dynamic>> items = _parseItems(order);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(order.orderId,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          // Copy order ID
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copy Order ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: order.orderId));
              KaapavToast.success(context, 'Copied!');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [

          // ── STATUS BANNER ──────────────────────────────────────
          GestureDetector(
            onTap: () => _showStatusPicker(context, order.status),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withValues(alpha: 0.85), statusColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$statusEmoji ${order.status.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Payment: ${order.paymentStatus}  •  Tap to change',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\u20B9${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                      if (_isUpdatingStatus)
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.edit_rounded, color: Colors.white54, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── ORDER ITEMS ────────────────────────────────────────
          if (items.isNotEmpty) ...[
            _SectionHeader(title: 'Items (${items.length})', icon: Icons.shopping_bag_outlined),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isLast = i == items.length - 1;
                  return _OrderItemRow(item: item, isLast: isLast, isDark: isDark);
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── CUSTOMER ───────────────────────────────────────────
          _SectionHeader(
  title: 'Customer',
  icon: Icons.person_outline_rounded,
),
const SizedBox(height: 8),
_InfoCard(isDark: isDark, rows: [
  _InfoRowData('Name', order.customerName ?? '-'),
  _InfoRowData('Phone', order.phone, copyable: true),
  // ✅ customerEmail is now String? in Order model
  if ((order.customerEmail ?? '').isNotEmpty)
    _InfoRowData('Email', order.customerEmail!),
]),

          // ── SHIPPING ADDRESS ────────────────────────────────────
          if (order.fullShippingAddress.isNotEmpty) ...[
            _SectionHeader(title: 'Shipping Address', icon: Icons.location_on_outlined),
            const SizedBox(height: 8),
            _InfoCard(isDark: isDark, rows: [
              _InfoRowData('Address', order.fullShippingAddress, multiline: true),
            ]),
            const SizedBox(height: 12),
          ],

          // ── AMOUNT BREAKDOWN ────────────────────────────────────
          _SectionHeader(title: 'Amount', icon: Icons.receipt_outlined),
          const SizedBox(height: 8),
          _InfoCard(isDark: isDark, rows: [
            _InfoRowData('Subtotal', '\u20B9${order.subtotal.toStringAsFixed(0)}'),
            if (order.shippingCost > 0)
              _InfoRowData('Shipping', '\u20B9${order.shippingCost.toStringAsFixed(0)}'),
            if (order.discount > 0)
              _InfoRowData('Discount', '-\u20B9${order.discount.toStringAsFixed(0)}',
                valueColor: const Color(0xFF10B981)),
            _InfoRowData('Total', '\u20B9${order.total.toStringAsFixed(0)}',
              bold: true, valueColor: KaapavTheme.gold),
          ]),
          const SizedBox(height: 12),

          // ── PAYMENT INFO ─────────────────────────────────────
          _SectionHeader(title: 'Payment', icon: Icons.payment_rounded),
          const SizedBox(height: 8),
          _InfoCard(isDark: isDark, rows: [
            _InfoRowData('Status', order.paymentStatus.toUpperCase(),
              valueColor: order.paymentStatus == 'paid'
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B)),
            if ((order.paymentId ?? '').isNotEmpty)
              _InfoRowData('Payment ID', order.paymentId ?? '', copyable: true),
            if ((order.paymentLink ?? '').isNotEmpty)
              _InfoRowData('Payment Link', order.paymentLink ?? '', copyable: true),
          ]),
          const SizedBox(height: 12),

          // ── TRACKING ───────────────────────────────────────────
          if (order.hasTracking) ...[
  _SectionHeader(
    title: 'Tracking',
    icon: Icons.local_shipping_outlined,
  ),
  const SizedBox(height: 8),
  _InfoCard(isDark: isDark, rows: [
    // ✅ FIX: awbNumber is nullable String? — use ?? '-'
    _InfoRowData('AWB', order.awbNumber ?? '-', copyable: true),
    _InfoRowData('Courier', order.courier ?? '-'),
    // ✅ FIX: trackingUrl is nullable String? — use ?? ''
    if ((order.trackingUrl ?? '').isNotEmpty)
      _InfoRowData('Track', order.trackingUrl ?? '', copyable: true),
  ]),
  const SizedBox(height: 12),
],
          // ── ORDER META ─────────────────────────────────────────
          _SectionHeader(title: 'Order Info', icon: Icons.info_outline_rounded),
          const SizedBox(height: 8),
          _InfoCard(isDark: isDark, rows: [
            _InfoRowData('Order ID', order.orderId, copyable: true),
            _InfoRowData('Source', order.source ?? 'catalogue'),
            _InfoRowData('Items', '${order.itemCount ?? items.length} item(s)'),
            if ((order.createdAt ?? '').isNotEmpty)
              _InfoRowData('Placed', _formatDate(order.createdAt ?? '')),
          ]),

          const SizedBox(height: 24),

          // ── ACTION BUTTONS ─────────────────────────────────────
          // Manual status change (always available)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showStatusPicker(context, order.status),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Change Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: statusColor,
                side: BorderSide(color: statusColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Confirm / Cancel
          if (order.canCancel)
            Row(
              children: [
                if (order.isPending)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm Order'),
                    ),
                  ),
                if (order.isPending) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelOrder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),

          // Payment link for unpaid orders
          if (order.isUnpaid) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generatePaymentLink,
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Generate & Send Payment Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaapavTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Parse items JSON safely ───────────────────────────────────
  List<Map<String, dynamic>> _parseItems(dynamic order) {
    try {
      final raw = order.items;
      if (raw == null) return [];
      if (raw is List) {
        return raw.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (raw is String && raw.isNotEmpty) {
        // Attempt parse if it's a JSON string
        // (depends on how your model exposes items)
        return [];
      }
    } catch (_) {}
    return [];
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
             '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Order Item Row ────────────────────────────────────────────
class _OrderItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  final bool isDark;
  const _OrderItemRow({required this.item, required this.isLast, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Product';
    final sku  = item['sku']?.toString() ?? '';
    final qty  = item['qty'] ?? item['quantity'] ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = item['image_url']?.toString() ?? item['image']?.toString();
    final lineTotal = price * (qty as num).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE5E7EB),
                ),
              ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F0E8),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: Icon(Icons.diamond_outlined, size: 20, color: Color(0xFFC49432)),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.diamond_outlined, size: 20, color: Color(0xFFC49432)),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.diamond_outlined, size: 20, color: Color(0xFFC49432)),
                  ),
          ),
          const SizedBox(width: 11),

          // Name + SKU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                if (sku.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sku, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
                const SizedBox(height: 4),
                Text('\u20B9$price × $qty',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),

          // Line total
          Text('\u20B9${lineTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 5),
        Text(title,
          style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF), letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────
class _InfoRowData {
  final String label;
  final String value;
  final bool copyable;
  final bool multiline;
  final bool bold;
  final Color? valueColor;
  const _InfoRowData(this.label, this.value,
      {this.copyable = false, this.multiline = false,
       this.bold = false, this.valueColor});
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<_InfoRowData> rows;
  const _InfoCard({required this.isDark, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: rows.map((row) => _buildRow(context, row)).toList(),
      ),
    );
  }

  Widget _buildRow(BuildContext context, _InfoRowData row) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueWidget = Text(
      row.value,
      style: TextStyle(
        fontSize: 13,
        fontWeight: row.bold ? FontWeight.w700 : FontWeight.w500,
        color: row.valueColor ?? (isDark ? Colors.white : const Color(0xFF374151)),
      ),
      textAlign: TextAlign.right,
      overflow: row.multiline ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: row.multiline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: row.multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(row.label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const SizedBox(width: 8),
          Expanded(
            child: row.copyable
                ? GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: row.value));
                      KaapavToast.success(context, 'Copied!');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(child: valueWidget),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded,
                          size: 12, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  )
                : Align(alignment: Alignment.centerRight, child: valueWidget),
          ),
        ],
      ),
    );
  }
}