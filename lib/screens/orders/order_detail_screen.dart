// lib/screens/orders/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../widgets/toast.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {

  // ✅ Extracted to State methods — here `context` = this.context,
  //    which the linter correctly recognises as guarded by `mounted`.
  Future<void> _confirmOrder() async {
    final ok = await ref.read(orderProvider.notifier).confirmOrder(widget.orderId);
    if (!mounted) return;
    if (ok) KaapavToast.success(context, 'Order confirmed');
  }

  Future<void> _cancelOrder() async {
    final ok = await ref.read(orderProvider.notifier).cancelOrder(widget.orderId);
    if (!mounted) return;
    if (ok) KaapavToast.warning(context, 'Order cancelled');
  }

  Future<void> _generatePaymentLink() async {
    final link = await ref.read(orderProvider.notifier).generatePaymentLink(widget.orderId);
    if (!mounted) return;
    if (link != null) KaapavToast.success(context, 'Payment link generated');
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider).orders
        .where((o) => o.orderId == widget.orderId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.orderId)),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderId),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${order.statusEmoji} ${order.status.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Payment: ${order.paymentStatus}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Text('₹${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _Section(title: 'Customer', children: [
            _DetailRow('Name', order.customerName ?? '-'),
            _DetailRow('Phone', order.phone),
          ]),
          const SizedBox(height: 12),

          _Section(title: 'Shipping Address', children: [
            if (order.fullShippingAddress.isNotEmpty)
              _DetailRow('Address', order.fullShippingAddress),
          ]),
          const SizedBox(height: 12),

          _Section(title: 'Amount', children: [
            _DetailRow('Subtotal', '₹${order.subtotal.toStringAsFixed(0)}'),
            if (order.discount > 0) _DetailRow('Discount', '-₹${order.discount.toStringAsFixed(0)}'),
            if (order.shippingCost > 0) _DetailRow('Shipping', '₹${order.shippingCost.toStringAsFixed(0)}'),
            _DetailRow('Total', '₹${order.total.toStringAsFixed(0)}'),
          ]),
          const SizedBox(height: 12),

          if (order.hasTracking)
            _Section(title: 'Tracking', children: [
              _DetailRow('AWB', order.awbNumber ?? '-'),
              _DetailRow('Courier', order.courier ?? '-'),
            ]),

          const SizedBox(height: 24),

          if (order.canCancel)
            Row(
              children: [
                if (order.isPending)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmOrder, // ✅ method ref, no inline async
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      child: const Text('Confirm'),
                    ),
                  ),
                if (order.isPending) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelOrder, // ✅
                    style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444))),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),

          if (order.isUnpaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generatePaymentLink, // ✅
                icon: const Icon(Icons.payment),
                label: const Text('Generate Payment Link'),
                style: ElevatedButton.styleFrom(backgroundColor: KaapavTheme.gold, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const Spacer(),
          Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF374151)),
              textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}