import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Order ID + Status ──
            Row(
              children: [
                Text(
                  order.orderId,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KaapavTheme.gold,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: order.status),
              ],
            ),

            const SizedBox(height: 10),

            // ── Customer info ──
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerName ?? order.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Items count + Total ──
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text(
                  '${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Payment + Date row ──
            Row(
              children: [
                _PaymentChip(status: order.paymentStatus),
                const Spacer(),
                Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),

            // ── Tracking info ──
            if (order.hasTracking) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0891B2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: Color(0xFF0891B2)),
                    const SizedBox(width: 4),
                    Text(
                      'AWB: ${order.awbNumber}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0891B2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
    } catch (_) {
      return '';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config.$3, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              color: config.$2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _getConfig() {
    switch (status) {
      case 'pending':
        return (const Color(0xFFFEF3C7), const Color(0xFFD97706), '⏳');
      case 'confirmed':
        return (const Color(0xFFDBEAFE), const Color(0xFF2563EB), '✅');
      case 'processing':
        return (const Color(0xFFEDE9FE), const Color(0xFF7C3AED), '⚙️');
      case 'shipped':
        return (const Color(0xFFCFFAFE), const Color(0xFF0891B2), '🚚');
      case 'delivered':
        return (const Color(0xFFD1FAE5), const Color(0xFF059669), '📦');
      case 'cancelled':
        return (const Color(0xFFFEE2E2), const Color(0xFFDC2626), '❌');
      case 'returned':
        return (const Color(0xFFFEE2E2), const Color(0xFFDC2626), '↩️');
      default:
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), '📋');
    }
  }
}

class _PaymentChip extends StatelessWidget {
  final String status;
  const _PaymentChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    final isRefunded = status == 'refunded';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPaid
            ? const Color(0xFFD1FAE5)
            : isRefunded
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPaid ? '💰 Paid' : isRefunded ? '↩️ Refunded' : '⏳ Unpaid',
        style: TextStyle(
          fontSize: 11,
          color: isPaid
              ? const Color(0xFF059669)
              : isRefunded
                  ? const Color(0xFFD97706)
                  : const Color(0xFFDC2626),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}