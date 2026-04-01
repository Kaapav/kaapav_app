// lib/screens/orders/order_detail_screen.dart

import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaapav_app/config/theme.dart';
import 'package:share_plus/share_plus.dart';


import '../../providers/order_provider.dart';
import '../../widgets/toast.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isUpdatingStatus = false;
  bool _isBookingShiprocket = false;
  bool _isLoadingOrder = false;
  bool _isUpdatingAwb = false;
  bool _isLoadingEvents = false;

  List<Map<String, dynamic>> _events = [];

  static const _statuses = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  static const _statusColors = {
    'pending': Color(0xFFF59E0B),
    'confirmed': Color(0xFF3B82F6),
    'processing': Color(0xFF8B5CF6),
    'shipped': Color(0xFF06B6D4),
    'delivered': Color(0xFF10B981),
    'cancelled': Color(0xFFEF4444),
  };

  static const _statusEmojis = {
    'pending': '⏳',
    'confirmed': '✅',
    'processing': '📦',
    'shipped': '🚚',
    'delivered': '🎉',
    'cancelled': '❌',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final orders = ref.read(orderProvider).orders;
      if (orders.isEmpty) {
        await ref.read(orderProvider.notifier).loadOrders();
      }
      await _ensureOrderLoaded();
      await _loadEvents();
    });
  }

  Future<void> _ensureOrderLoaded() async {
    final existing =
        ref.read(orderProvider.notifier).getOrderById(widget.orderId);
    if (existing != null) return;

    if (mounted) setState(() => _isLoadingOrder = true);
    try {
      await ref.read(orderProvider.notifier).fetchOrderById(widget.orderId);
    } finally {
      if (mounted) setState(() => _isLoadingOrder = false);
    }
  }

  Future<void> _loadEvents() async {
    if (mounted) setState(() => _isLoadingEvents = true);
    try {
      final list = await ref
          .read(orderProvider.notifier)
          .getOrderEvents(widget.orderId);
      if (mounted) {
        setState(() => _events = list);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _events = []);
      }
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final ok = await ref.read(orderProvider.notifier).updateOrderStatus(
            widget.orderId,
            newStatus,
          );
      if (!mounted) return;

      if (ok) {
        KaapavToast.success(context, 'Status updated to $newStatus');
        await _loadEvents();
      } else {
        KaapavToast.error(context, 'Failed to update status');
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _bookShiprocket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Book Shiprocket?'),
        content: const Text(
          'This will create a shipment in Shiprocket and notify the customer on WhatsApp.\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KaapavTheme.gold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Book'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBookingShiprocket = true);

    try {
      final result = await ref
          .read(orderProvider.notifier)
          .bookShiprocket(widget.orderId);

      if (!mounted) return;

      if (result['success'] == true) {
        final srId = result['shiprocketOrderId'] ?? '';
        KaapavToast.success(
          context,
          srId.toString().isNotEmpty
              ? 'Shiprocket booked! SR ID: $srId'
              : 'Shiprocket booked successfully!',
        );
        await ref.read(orderProvider.notifier).loadOrders(silent: true);
        await _loadEvents();
      } else {
        KaapavToast.error(
          context,
          result['message'] ?? 'Shiprocket booking failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isBookingShiprocket = false);
    }
  }

  Future<void> _updateAwb() async {
    final awbCtrl = TextEditingController();
    final courierCtrl = TextEditingController(text: 'Shiprocket');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add AWB'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: awbCtrl,
              decoration: const InputDecoration(
                labelText: 'AWB Number',
                hintText: 'Enter AWB',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: courierCtrl,
              decoration: const InputDecoration(
                labelText: 'Courier',
                hintText: 'Enter courier',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'awb': awbCtrl.text.trim(),
                'courier': courierCtrl.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final awb = result['awb'] ?? '';
    final courier = result['courier'] ?? 'Shiprocket';

    if (awb.isEmpty) {
      KaapavToast.error(context, 'AWB is required');
      return;
    }

    setState(() => _isUpdatingAwb = true);
    try {
      final ok = await ref.read(orderProvider.notifier).updateAwb(
            widget.orderId,
            awb: awb,
            courier: courier,
          );

      if (!mounted) return;

      if (ok) {
        KaapavToast.success(context, 'AWB updated successfully');
        await ref.read(orderProvider.notifier).loadOrders(silent: true);
        await _loadEvents();
      } else {
        KaapavToast.error(context, 'Failed to update AWB');
      }
    } finally {
      if (mounted) setState(() => _isUpdatingAwb = false);
    }
  }

  Future<void> _resendWhatsApp(String type) async {
    try {
      await ref
          .read(orderProvider.notifier)
          .sendNotification(widget.orderId, type);
      if (!mounted) return;
      KaapavToast.success(context, 'WhatsApp sent!');
    } catch (_) {
      KaapavToast.error(context, 'Failed to send');
    }
  }

  Future<void> _downloadInvoice(String orderId) async {
    try {
      KaapavToast.success(context, 'Downloading invoice...');

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/Invoice_$orderId.pdf';

      final ok = await ref.read(orderProvider.notifier).downloadInvoicePdf(orderId, path);
      if (!ok) {
        if (mounted) KaapavToast.error(context, 'Failed to download');
        return;
      }

      await OpenFilex.open(path);
      if (mounted) KaapavToast.success(context, 'Invoice downloaded!');
    } catch (e) {
      if (mounted) KaapavToast.error(context, 'Download failed: $e');
    }
  }

  Future<void> _sendInvoiceToCustomer(String orderId) async {
    try {
      await ref.read(orderProvider.notifier).sendInvoice(orderId);
      if (!mounted) return;
      KaapavToast.success(context, 'Invoice sent to customer on WhatsApp!');
    } catch (_) {
      if (mounted) KaapavToast.error(context, 'Failed to send invoice');
    }
  }

  Future<void> _saveNotes(String notes) async {
    try {
      final ok = await ref
          .read(orderProvider.notifier)
          .updateOrderNotes(widget.orderId, notes);

      if (!mounted) return;
      if (ok) {
        KaapavToast.success(context, 'Notes saved');
      } else {
        KaapavToast.error(context, 'Failed to save notes');
      }
    } catch (_) {
      if (!mounted) return;
      KaapavToast.error(context, 'Failed to save notes');
    }
  }

    Future<void> _editCustomerDetails(order) async {
    final nameCtrl = TextEditingController(text: order.customerName ?? '');
    final phoneCtrl = TextEditingController(text: order.phone);
    final shippingNameCtrl =
        TextEditingController(text: order.shippingName ?? order.customerName ?? '');
    final addressCtrl = TextEditingController(text: order.shippingAddress ?? '');
    final cityCtrl = TextEditingController(text: order.shippingCity ?? '');
    final stateCtrl = TextEditingController(text: order.shippingState ?? '');
    final pincodeCtrl = TextEditingController(text: order.shippingPincode ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: shippingNameCtrl,
                decoration: const InputDecoration(labelText: 'Shipping Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stateCtrl,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pincodeCtrl,
                decoration: const InputDecoration(labelText: 'Pincode'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final ok = await ref.read(orderProvider.notifier).updateOrderDetails(
          widget.orderId,
          customerName: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          shippingName: shippingNameCtrl.text.trim(),
          shippingAddress: addressCtrl.text.trim(),
          shippingCity: cityCtrl.text.trim(),
          shippingState: stateCtrl.text.trim(),
          shippingPincode: pincodeCtrl.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      KaapavToast.success(context, 'Customer details updated');
      await ref.read(orderProvider.notifier).loadOrders(silent: true);
    } else {
      KaapavToast.error(context, 'Failed to update details');
    }
  }

    Future<void> _editPaymentDetails(order) async {
    String selectedPaymentStatus = order.paymentStatus;
    final paymentIdCtrl = TextEditingController(text: order.paymentId ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPaymentStatus,
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                    DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedPaymentStatus = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paymentIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Payment ID',
                    hintText: 'Enter payment ID',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;

    final ok = await ref.read(orderProvider.notifier).updateOrderPayment(
          widget.orderId,
          paymentStatus: selectedPaymentStatus,
          paymentId: paymentIdCtrl.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      KaapavToast.success(context, 'Payment updated');
      await ref.read(orderProvider.notifier).loadOrders(silent: true);
    } else {
      KaapavToast.error(context, 'Failed to update payment');
    }
  }

  Future<void> _confirmOrder() async {
    final paymentIdController = TextEditingController();

    final paymentId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: TextField(
          controller: paymentIdController,
          decoration: const InputDecoration(
            labelText: 'Payment ID',
            hintText: 'Enter payment ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, paymentIdController.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (paymentId == null || paymentId.isEmpty) return;

    final order = ref.read(orderProvider).orders.firstWhere(
          (o) => o.orderId == widget.orderId,
        );

    final ok = await ref.read(orderProvider.notifier).confirmOrder(
          widget.orderId,
          paymentId: paymentId,
          phone: order.phone,
        );

    if (!mounted) return;
    if (ok) {
      KaapavToast.success(context, 'Order confirmed');
      await ref.read(orderProvider.notifier).loadOrders(silent: true);
      await _loadEvents();
    } else {
      KaapavToast.error(context, 'Failed to confirm order');
    }
  }

    Future<void> _cancelOrder() async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This cannot be undone. Enter a reason to continue.'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Cancel reason',
                hintText: 'Enter reason',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await ref.read(orderProvider.notifier).cancelOrder(
          widget.orderId,
          reason: reasonCtrl.text.trim().isEmpty
              ? 'Cancelled by admin'
              : reasonCtrl.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      KaapavToast.warning(context, 'Order cancelled');
    } else {
      KaapavToast.error(context, 'Failed to cancel order');
    }
  }

    Future<void> _generatePaymentLink() async {
    debugPrint('PAYMENT LINK BUTTON CLICKED for ${widget.orderId}');

    final link =
        await ref.read(orderProvider.notifier).generatePaymentLink(widget.orderId);

    debugPrint('PAYMENT LINK RESULT => $link');

    if (!mounted) return;

    if (link != null && link.isNotEmpty) {
      KaapavToast.success(
        context,
        'Payment link generated & sent on WhatsApp',
      );
    } else {
      final providerError = ref.read(orderProvider).error;
      debugPrint('PAYMENT LINK FINAL ERROR => $providerError');
      KaapavToast.error(
        context,
        providerError ?? 'Failed to generate payment link',
      );
    }
  }

  void _shareOrder(order) {
    final lines = [
      '🛍️ *Order: ${order.orderId}*',
      '👤 ${order.customerName ?? order.phone}',
      '📱 ${order.phone}',
      '',
      '📦 Status: ${order.status.toUpperCase()}',
      '💳 Payment: ${order.paymentStatus.toUpperCase()}',
      '',
      '💰 Total: ₹${order.total.toStringAsFixed(0)}',
      if (order.fullShippingAddress.isNotEmpty) '📍 ${order.fullShippingAddress}',
      if ((order.awbNumber ?? '').isNotEmpty) '🚚 AWB: ${order.awbNumber}',
      '',
      '📅 ${_formatDate(order.createdAt ?? '')}',
    ];
    Share.share(lines.join('\n'));
  }

  void _showEditOrderSheet(order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedStatus = order.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Edit Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: selectedStatus,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedStatus = value);
                        }
                      },
                      child: Column(
                        children: _statuses.map((status) {
                          final color = _statusColors[status] ?? KaapavTheme.gold;
                          return Theme(
                            data: Theme.of(context).copyWith(
                              radioTheme: RadioThemeData(
                                fillColor: WidgetStatePropertyAll(color),
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: status,
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Text(_statusEmojis[status] ?? '•'),
                                  const SizedBox(width: 8),
                                  Text(
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdatingStatus
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                if (selectedStatus != order.status) {
                                  await _changeStatus(selectedStatus);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KaapavTheme.gold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Status'),
                      ),
                    ),
                    if (order.status == 'confirmed' &&
                        order.paymentStatus == 'paid') ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isBookingShiprocket
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await _bookShiprocket();
                                },
                          icon: _isBookingShiprocket
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.local_shipping_rounded),
                          label: Text(
                            _isBookingShiprocket
                                ? 'Booking Shiprocket...'
                                : 'Book Shiprocket',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderProvider).orders;
    final order = orders.any((o) => o.orderId == widget.orderId)
        ? orders.firstWhere((o) => o.orderId == widget.orderId)
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.orderId)),
        body: Center(
          child: _isLoadingOrder
              ? const CircularProgressIndicator(color: KaapavTheme.gold)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Order not found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _ensureOrderLoaded,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KaapavTheme.gold,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
        ),
      );
    }

    final statusColor = _statusColors[order.status] ?? KaapavTheme.gold;
    final statusEmoji = _statusEmojis[order.status] ?? '📋';
    final items = _parseItems(order);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          order.orderId,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
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
          GestureDetector(
            onTap: () => _showEditOrderSheet(order),
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
                      Text(
                        '$statusEmoji ${order.status.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment: ${order.paymentStatus} • Tap to edit',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_isUpdatingStatus)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(Icons.edit_rounded,
                            color: Colors.white54, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.label_outline_rounded,
                label: order.source.isNotEmpty
                    ? 'Source: ${order.source[0].toUpperCase()}${order.source.substring(1)}'
                    : 'Source: Unknown',
                bg: const Color(0xFFF3F4F6),
                fg: const Color(0xFF6B7280),
              ),
              if (order.status == 'confirmed' && order.paymentStatus == 'paid')
                const _MetaChip(
                  icon: Icons.local_shipping_rounded,
                  label: 'Ready for Shiprocket',
                  bg: Color(0xFFEDE9FE),
                  fg: Color(0xFF7C3AED),
                ),
              if ((order.shiprocketOrderId ?? '').isNotEmpty)
                _MetaChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'SR ID: ${order.shiprocketOrderId}',
                  bg: const Color(0xFFEDE9FE),
                  fg: const Color(0xFF7C3AED),
                ),
            ],
          ),

          const SizedBox(height: 12),

          _SectionHeader(title: 'Order Timeline', icon: Icons.timeline_rounded),
          const SizedBox(height: 8),
          _OrderTimeline(currentStatus: order.status),
          const SizedBox(height: 12),

          if (items.isNotEmpty) ...[
            _SectionHeader(
              title: 'Items (${items.length})',
              icon: Icons.shopping_bag_outlined,
            ),
            const SizedBox(height: 8),
            Container(
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
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isLast = i == items.length - 1;
                  return _OrderItemRow(
                    item: item,
                    isLast: isLast,
                    isDark: isDark,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          _SectionHeader(title: 'Customer', icon: Icons.person_outline_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            isDark: isDark,
            rows: [
              _InfoRowData('Name', order.customerName ?? '-'),
              _InfoRowData('Phone', order.phone, copyable: true),
              if ((order.customerEmail ?? '').isNotEmpty)
                _InfoRowData('Email', order.customerEmail!),
            ],
          ),

          if (order.fullShippingAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Shipping Address',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 8),
            _InfoCard(
              isDark: isDark,
              rows: [
                _InfoRowData(
                  'Address',
                  order.fullShippingAddress,
                  multiline: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          _SectionHeader(title: 'Amount', icon: Icons.receipt_outlined),
          const SizedBox(height: 8),
          _InfoCard(
            isDark: isDark,
            rows: [
              _InfoRowData('Subtotal', '₹${order.subtotal.toStringAsFixed(0)}'),
              if (order.shippingCost > 0)
                _InfoRowData(
                  'Shipping',
                  '₹${order.shippingCost.toStringAsFixed(0)}',
                ),
              if (order.discount > 0)
                _InfoRowData(
                  'Discount',
                  '-₹${order.discount.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF10B981),
                ),
              _InfoRowData(
                'Total',
                '₹${order.total.toStringAsFixed(0)}',
                bold: true,
                valueColor: KaapavTheme.gold,
              ),
            ],
          ),

          const SizedBox(height: 12),

          _SectionHeader(title: 'Payment', icon: Icons.payment_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            isDark: isDark,
            rows: [
              _InfoRowData(
                'Status',
                order.paymentStatus.toUpperCase(),
                valueColor: order.paymentStatus == 'paid'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
              if ((order.paymentId ?? '').isNotEmpty)
                _InfoRowData('Payment ID', order.paymentId ?? '', copyable: true),
              if ((order.paymentLink ?? '').isNotEmpty)
                _InfoRowData('Payment Link', order.paymentLink ?? '', copyable: true),
            ],
          ),

          const SizedBox(height: 12),

          if (order.hasTracking) ...[
            _SectionHeader(
              title: 'Tracking',
              icon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 8),
            _InfoCard(
              isDark: isDark,
              rows: [
                _InfoRowData('AWB', order.awbNumber ?? '-', copyable: true),
                _InfoRowData('Courier', order.courier ?? '-'),
                if ((order.trackingUrl ?? '').isNotEmpty)
                  _InfoRowData('Track', order.trackingUrl ?? '', copyable: true),
              ],
            ),
            const SizedBox(height: 12),
          ],

          _SectionHeader(title: 'Order Info', icon: Icons.info_outline_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            isDark: isDark,
            rows: [
              _InfoRowData('Order ID', order.orderId, copyable: true),
              _InfoRowData('Source', order.source),
              _InfoRowData(
                'Items',
                '${order.itemCount > 0 ? order.itemCount : items.length} item(s)',
              ),
	                      if ((order.cancellationReason ?? '').isNotEmpty)
                _InfoRowData(
                  'Cancel Reason',
                  order.cancellationReason ?? '',
                  multiline: true,
                ),
              if ((order.createdAt ?? '').isNotEmpty)
                _InfoRowData('Placed', _formatDate(order.createdAt ?? '')),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditOrderSheet(order),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: statusColor,
                side: BorderSide(color: statusColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

                    Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editCustomerDetails(order),
                  icon: const Icon(Icons.person_rounded),
                  label: const Text('Edit Customer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editPaymentDetails(order),
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('Edit Payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

                    if (order.status == 'confirmed' && order.paymentStatus == 'paid') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isBookingShiprocket ? null : _bookShiprocket,
                icon: _isBookingShiprocket
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.local_shipping_rounded),
                label: Text(
                  _isBookingShiprocket
                      ? 'Booking Shiprocket...'
                      : 'Book Shiprocket',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (order.status == 'processing' || order.status == 'confirmed') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUpdatingAwb ? null : _updateAwb,
                icon: _isUpdatingAwb
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KaapavTheme.gold,
                        ),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: Text(
                  _isUpdatingAwb ? 'Saving AWB...' : 'Add / Update AWB',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF06B6D4),
                  side: const BorderSide(color: Color(0xFF06B6D4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

            Row(
            children: [
              if (order.paymentStatus != 'paid')
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Confirm Payment'),
                  ),
                ),
              if (order.paymentStatus != 'paid' && order.canCancel)
                const SizedBox(width: 10),
              if (order.canCancel)
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

          const SizedBox(height: 12),
          _SectionHeader(title: 'Internal Notes', icon: Icons.note_outlined),
          const SizedBox(height: 8),
          _NotesField(
            initialValue: order.internalNotes ?? '',
            onSave: _saveNotes,
            isDark: isDark,
          ),

          const SizedBox(height: 12),
          // ── INVOICE ────────────────────────────────────────────────
_SectionHeader(title: 'Invoice', icon: Icons.receipt_long_rounded),
const SizedBox(height: 8),
Row(children: [
  Expanded(
    child: OutlinedButton.icon(
      onPressed: () => _downloadInvoice(order.orderId),
      icon: const Icon(Icons.download_rounded, size: 16),
      label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: KaapavTheme.gold,
        side: const BorderSide(color: KaapavTheme.gold),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  ),
  const SizedBox(width: 8),
  Expanded(
    child: OutlinedButton.icon(
      onPressed: () => _sendInvoiceToCustomer(order.orderId),
      icon: const Icon(Icons.send_rounded, size: 16),
      label: const Text('Send to Customer', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF10B981),
        side: const BorderSide(color: Color(0xFF10B981)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  ),
]),
const SizedBox(height: 12),

// ── WHATSAPP RESEND ────────────────────────────────────────
_SectionHeader(title: 'WhatsApp', icon: Icons.chat_rounded),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _resendWhatsApp('confirmation'),
                  icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                  label: const Text(
                    'Confirmation',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      order.hasTracking ? () => _resendWhatsApp('shipped') : null,
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: const Text(
                    'Tracking',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6D4),
                    side: const BorderSide(color: Color(0xFF06B6D4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareOrder(order),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KaapavTheme.gold,
                    side: const BorderSide(color: KaapavTheme.gold),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: order.isUnpaid ? _generatePaymentLink : null,
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: const Text('Send Payment Reminder'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 12),
          _SectionHeader(title: 'Order Events', icon: Icons.history_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: _isLoadingEvents
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: KaapavTheme.gold),
                    ),
                  )
                : _events.isEmpty
                    ? const Text(
                        'No events yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      )
                    : Column(
                        children: _events.map((e) {
                          final type = (e['event_type'] ?? 'event').toString();
                          final msg = (e['message'] ?? '').toString();
                          final createdAt = (e['created_at'] ?? '').toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.fiber_manual_record,
                                  size: 10,
                                  color: KaapavTheme.gold,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      if (msg.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          msg,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parseItems(dynamic order) {
    try {
      final raw = order.items;
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (raw is String && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          return decoded
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _OrderTimeline extends StatelessWidget {
  final String currentStatus;
  const _OrderTimeline({required this.currentStatus});

  static const _steps = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
  ];

  static const _labels = [
    'Pending',
    'Confirmed',
    'Packing',
    'Shipped',
    'Delivered',
  ];

  static const _icons = [
    Icons.hourglass_empty_rounded,
    Icons.check_circle_outline_rounded,
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
    Icons.done_all_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cancelled = currentStatus == 'cancelled';
    final currentIdx = cancelled ? -1 : _steps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: cancelled
          ? const Row(
              children: [
                Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            )
          : Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final filled = (i ~/ 2) < currentIdx;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: filled
                          ? KaapavTheme.gold
                          : const Color(0xFFE5E7EB),
                    ),
                  );
                }

                final idx = i ~/ 2;
                final done = idx <= currentIdx;
                final active = idx == currentIdx;
                final color =
                    done ? KaapavTheme.gold : const Color(0xFFD1D5DB);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: done
                            ? KaapavTheme.gold.withValues(
                                alpha: active ? 1 : 0.15,
                              )
                            : (isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFF3F4F6)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              done ? KaapavTheme.gold : const Color(0xFFE5E7EB),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _icons[idx],
                        size: 15,
                        color: active ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _labels[idx],
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w400,
                        color: active
                            ? KaapavTheme.gold
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  final bool isDark;

  const _OrderItemRow({
    required this.item,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Product';
    final category = item['category']?.toString() ?? '';
    final sku = item['sku']?.toString() ?? '';
    final qty = item['qty'] ?? item['quantity'] ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final imageUrl =
        item['image_url']?.toString() ?? item['image']?.toString();
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
          Container(
            width: 52,
            height: 52,
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
                      child: Icon(
                        Icons.diamond_outlined,
                        size: 20,
                        color: Color(0xFFC49432),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.diamond_outlined,
                        size: 20,
                        color: Color(0xFFC49432),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.diamond_outlined,
                      size: 20,
                      color: Color(0xFFC49432),
                    ),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.isNotEmpty || sku.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category.isNotEmpty && sku.isNotEmpty
                        ? '$category • $sku'
                        : (category.isNotEmpty ? category : sku),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '₹$price × $qty',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${lineTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _InfoRowData {
  final String label;
  final String value;
  final bool copyable;
  final bool multiline;
  final bool bold;
  final Color? valueColor;

  const _InfoRowData(
    this.label,
    this.value, {
    this.copyable = false,
    this.multiline = false,
    this.bold = false,
    this.valueColor,
  });
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<_InfoRowData> rows;

  const _InfoCard({
    required this.isDark,
    required this.rows,
  });

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
        color:
            row.valueColor ?? (isDark ? Colors.white : const Color(0xFF374151)),
      ),
      textAlign: TextAlign.right,
      overflow: row.multiline ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: row.multiline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            row.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            row.label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
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
                        const Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: valueWidget,
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatefulWidget {
  final String initialValue;
  final Future<void> Function(String) onSave;
  final bool isDark;

  const _NotesField({
    required this.initialValue,
    required this.onSave,
    required this.isDark,
  });

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: _ctrl,
        maxLines: 3,
        style: TextStyle(
          fontSize: 13,
          color: widget.isDark ? Colors.white : const Color(0xFF374151),
        ),
        decoration: InputDecoration(
          hintText: 'Add internal notes (not visible to customer)...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
          suffixIcon: _saving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KaapavTheme.gold,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.save_rounded,
                    color: KaapavTheme.gold,
                    size: 20,
                  ),
                  onPressed: () async {
                    setState(() => _saving = true);
                    await widget.onSave(_ctrl.text.trim());
                    if (mounted) setState(() => _saving = false);
                  },
                ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}