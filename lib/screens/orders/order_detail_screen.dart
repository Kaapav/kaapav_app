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
import 'package:url_launcher/url_launcher.dart';
import '../../providers/product_provider.dart';
import '../products/product_detail_screen.dart';

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
  bool _isLoadingReturnRequests = false;

  String? _reviewingReturnRequestId;

  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _returnRequests = [];

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

  bool _hasActiveShipment(dynamic order) {
    return (order.shiprocketOrderId ?? '').toString().isNotEmpty ||
        (order.shipmentId ?? '').toString().isNotEmpty ||
        (order.awbNumber ?? '').toString().isNotEmpty ||
        (order.awbCode ?? '').toString().isNotEmpty ||
        (order.trackingId ?? '').toString().isNotEmpty ||
        (order.trackingUrl ?? '').toString().isNotEmpty ||
        order.status == 'shipped' ||
        order.status == 'delivered';
  }

  bool _canBookShiprocket(dynamic order) {
    return order.paymentStatus == 'paid' &&
        (order.status == 'confirmed' || order.status == 'processing') &&
        !_hasActiveShipment(order);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final orders = ref.read(orderProvider).orders;
      if (orders.isEmpty) {
        await ref.read(orderProvider.notifier).loadOrders();
      }
      await _ensureOrderLoaded();

      final products = ref.read(productProvider).products;
      if (products.isEmpty) {
        await ref.read(productProvider.notifier).loadProducts();
      }

      await _loadEvents();
      await _loadReturnRequests();
    });
  }

  Future<void> _ensureOrderLoaded() async {
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
      final list =
          await ref.read(orderProvider.notifier).getOrderEvents(widget.orderId);
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

  Future<void> _loadReturnRequests() async {
    if (mounted) {
      setState(
        () => _isLoadingReturnRequests = true,
      );
    }

    try {
      final requests =
          await ref.read(orderProvider.notifier).getOrderReturnRequests(
                widget.orderId,
              );

      if (!mounted) return;

      setState(
        () => _returnRequests = requests,
      );
    } finally {
      if (mounted) {
        setState(
          () => _isLoadingReturnRequests = false,
        );
      }
    }
  }

  Future<void> _reviewReturnRequest(
    Map<String, dynamic> returnRequest,
    String decision,
  ) async {
    if (_reviewingReturnRequestId != null) {
      return;
    }

    final requestId = (returnRequest['request_id'] ?? '').toString().trim();

    if (requestId.isEmpty) {
      KaapavToast.error(
        context,
        'Return request ID is missing',
      );
      return;
    }

    final isApproval = decision == 'approved';

    final noteController = TextEditingController();

    String? dialogError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                isApproval ? 'Approve request?' : 'Reject request?',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isApproval
                          ? 'This records the approval and attempts to notify the customer on WhatsApp. It does not start a refund, pickup, or exchange shipment.'
                          : 'Enter the rejection reason. The decision will be recorded and the customer notification will be attempted.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      autofocus: !isApproval,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isApproval
                            ? 'Owner note (optional)'
                            : 'Rejection reason',
                        hintText: isApproval
                            ? 'Add an internal approval note'
                            : 'Explain why the request is rejected',
                        errorText: dialogError,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final note = noteController.text.trim();

                    if (!isApproval && note.isEmpty) {
                      setDialogState(
                        () {
                          dialogError = 'Rejection reason is required';
                        },
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApproval
                        ? const Color(
                            0xFF10B981,
                          )
                        : const Color(
                            0xFFEF4444,
                          ),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isApproval ? 'Approve' : 'Reject',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final ownerNote = noteController.text.trim();

    noteController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(
      () {
        _reviewingReturnRequestId = requestId;
      },
    );

    try {
      final success =
          await ref.read(orderProvider.notifier).reviewOrderReturnRequest(
                widget.orderId,
                requestId,
                decision: decision,
                ownerNote: ownerNote,
              );

      if (!mounted) return;

      if (success) {
        KaapavToast.success(
          context,
          isApproval
              ? 'Request approved. Customer notification attempted.'
              : 'Request rejected. Customer notification attempted.',
        );

        await _loadReturnRequests();
        await _loadEvents();
      } else {
        final providerError = ref.read(orderProvider).error;

        KaapavToast.error(
          context,
          providerError ?? 'Failed to review return request',
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _reviewingReturnRequestId = null;
          },
        );
      }
    }
  }

  Future<void> _scheduleReturnPickup(
    Map<String, dynamic> returnRequest,
  ) async {
    if (_reviewingReturnRequestId != null) {
      return;
    }

    final requestId = (returnRequest['request_id'] ?? '').toString().trim();

    if (requestId.isEmpty) {
      KaapavToast.error(
        context,
        'Return request ID is missing',
      );
      return;
    }

    final courierController = TextEditingController(
      text: (returnRequest['return_courier'] ?? '').toString(),
    );
    final awbController = TextEditingController(
      text: (returnRequest['return_awb_number'] ?? '').toString(),
    );
    final dateController = TextEditingController(
      text: (returnRequest['pickup_scheduled_date'] ?? '').toString(),
    );
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule Return Pickup'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter reverse logistics details. The customer will receive tracking links via WhatsApp.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: courierController,
                      decoration: const InputDecoration(
                        labelText: 'Courier Partner',
                        hintText: 'e.g. Delhivery, Shiprocket, Blue Dart, DTDC',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: awbController,
                      decoration: const InputDecoration(
                        labelText: 'Return AWB / Tracking No.',
                        hintText: 'e.g. 14238920192',
                        prefixIcon: Icon(Icons.qr_code_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Date',
                        hintText: 'e.g. 28 Aug 2026',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Owner note (optional)',
                        hintText: 'e.g. Scheduled for afternoon slot',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Save & Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final courier = courierController.text.trim();
    final awb = awbController.text.trim();
    final pickupDate = dateController.text.trim();
    final ownerNote = noteController.text.trim();

    courierController.dispose();
    awbController.dispose();
    dateController.dispose();
    noteController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _reviewingReturnRequestId = requestId;
    });

    try {
      final success = await ref
          .read(orderProvider.notifier)
          .scheduleOrderReturnPickup(
            widget.orderId,
            requestId,
            courier: courier,
            awbNumber: awb,
            pickupScheduledDate: pickupDate,
            ownerNote: ownerNote,
          );

      if (!mounted) return;

      if (success) {
        KaapavToast.success(
          context,
          'Pickup scheduled with tracking. Customer notified on WhatsApp.',
        );
        await _loadReturnRequests();
        await _loadEvents();
      } else {
        KaapavToast.error(
          context,
          ref.read(orderProvider).error ?? 'Failed to schedule return pickup',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _reviewingReturnRequestId = null;
        });
      }
    }
  }

  Future<void> _markReturnPickedUp(
    Map<String, dynamic> returnRequest,
  ) async {
    if (_reviewingReturnRequestId != null) {
      return;
    }

    final requestId = (returnRequest['request_id'] ?? '').toString().trim();

    if (requestId.isEmpty) {
      KaapavToast.error(
        context,
        'Return request ID is missing',
      );
      return;
    }

    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm package picked up?',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use this only after the customer package has actually been collected. This records the status and attempts to notify the customer on WhatsApp.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'This does not verify the pickup with Shiprocket and does not start a refund or exchange shipment.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Owner note (optional)',
                    hintText: 'Example: Courier pickup confirmed',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.inventory_2_outlined,
              ),
              label: const Text(
                'Confirm Picked Up',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF2563EB,
                ),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    final ownerNote = noteController.text.trim();

    noteController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(
      () {
        _reviewingReturnRequestId = requestId;
      },
    );

    try {
      final success =
          await ref.read(orderProvider.notifier).markOrderReturnPickedUp(
                widget.orderId,
                requestId,
                ownerNote: ownerNote,
              );

      if (!mounted) return;

      if (success) {
        KaapavToast.success(
          context,
          'Package marked as picked up. Customer notification attempted.',
        );

        await _loadReturnRequests();
        await _loadEvents();
      } else {
        final providerError = ref.read(orderProvider).error;

        KaapavToast.error(
          context,
          providerError ?? 'Failed to confirm return pickup',
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _reviewingReturnRequestId = null;
          },
        );
      }
    }
  }

  Future<void> _markReturnReceived(
    Map<String, dynamic> returnRequest,
  ) async {
    if (_reviewingReturnRequestId != null) {
      return;
    }

    final requestId = (returnRequest['request_id'] ?? '').toString().trim();

    if (requestId.isEmpty) {
      KaapavToast.error(
        context,
        'Return request ID is missing',
      );
      return;
    }

    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm package received?',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use this only after the returned package has physically reached the return facility.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'This records the received status and attempts to notify the customer. It does not complete quality inspection, initiate a refund, or ship an exchange.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Owner note (optional)',
                    hintText: 'Example: Package received at warehouse',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.move_to_inbox_outlined,
              ),
              label: const Text(
                'Confirm Received',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF0F766E,
                ),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    final ownerNote = noteController.text.trim();

    noteController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(
      () {
        _reviewingReturnRequestId = requestId;
      },
    );

    try {
      final success =
          await ref.read(orderProvider.notifier).markOrderReturnReceived(
                widget.orderId,
                requestId,
                ownerNote: ownerNote,
              );

      if (!mounted) return;

      if (success) {
        KaapavToast.success(
          context,
          'Package marked as received. Customer notification attempted.',
        );

        await _loadReturnRequests();
        await _loadEvents();
      } else {
        final providerError = ref.read(orderProvider).error;

        KaapavToast.error(
          context,
          providerError ?? 'Failed to mark return package as received',
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _reviewingReturnRequestId = null;
          },
        );
      }
    }
  }

  Future<void> _reviewReturnQc(
    Map<String, dynamic> returnRequest,
    String decision,
  ) async {
    if (_reviewingReturnRequestId != null) {
      return;
    }

    final requestId = (returnRequest['request_id'] ?? '').toString().trim();

    if (requestId.isEmpty) {
      KaapavToast.error(
        context,
        'Return request ID is missing',
      );
      return;
    }

    final isPassed = decision == 'passed';
    final requestType = (returnRequest['request_type'] ?? 'return').toString().toLowerCase();
    final isReturn = requestType == 'return';

    var autoRefund = isReturn;
    var deductFee = false;
    final noteController = TextEditingController();
    String? dialogError;

    final confirmed = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isPassed
                    ? (isReturn ? 'Pass QC & Process Refund?' : 'Pass QC inspection?')
                    : 'Fail QC inspection?',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPassed
                          ? (isReturn
                              ? 'Returned items have passed inspection. You can auto-trigger Razorpay refund and choose whether to deduct the ₹60 reverse shipping fee.'
                              : 'Confirm that the returned exchange items are in acceptable condition.')
                          : 'Record why the returned items failed quality inspection.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (isPassed && isReturn) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: autoRefund,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text(
                                '⚡ 1-Click Auto Refund via Razorpay',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              subtitle: const Text(
                                'Immediately issues refund & sends WhatsApp receipt with Refund ID.',
                                style: TextStyle(fontSize: 11),
                              ),
                              onChanged: (val) {
                                setDialogState(() {
                                  autoRefund = val == true;
                                });
                              },
                            ),
                            const Divider(height: 16),
                            CheckboxListTile(
                              value: deductFee,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text(
                                'Deduct ₹60 reverse shipping fee',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: const Text(
                                'Uncheck for full product value refund.',
                                style: TextStyle(fontSize: 11),
                              ),
                              onChanged: (val) {
                                setDialogState(() {
                                  deductFee = val == true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      autofocus: !isPassed,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isPassed
                            ? 'Inspection note (optional)'
                            : 'QC failure reason *',
                        hintText: isPassed
                            ? 'Example: Verified tags & original jewelry condition'
                            : 'Explain the damage or issue',
                        errorText: dialogError,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final ownerNote = noteController.text.trim();
                    if (!isPassed && ownerNote.isEmpty) {
                      setDialogState(() {
                        dialogError = 'QC failure reason is required';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, {
                      'confirmed': true,
                      'autoRefund': autoRefund,
                      'deductFee': deductFee,
                      'ownerNote': ownerNote,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPassed
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isPassed
                        ? (isReturn && autoRefund ? 'Approve & Auto-Refund' : 'Confirm QC Passed')
                        : 'Confirm QC Failed',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();

    if (confirmed == null || confirmed['confirmed'] != true || !mounted) {
      return;
    }

    final ownerNote = (confirmed['ownerNote'] ?? '').toString();
    final shouldAutoRefund = confirmed['autoRefund'] == true;
    final shouldDeductFee = confirmed['deductFee'] == true;

    setState(() {
      _reviewingReturnRequestId = requestId;
    });

    try {
      final result = await ref.read(orderProvider.notifier).reviewOrderReturnQc(
            widget.orderId,
            requestId,
            decision: decision,
            ownerNote: ownerNote,
            deductReverseShippingFee: shouldDeductFee,
            autoRefund: shouldAutoRefund,
          );

      if (!mounted) return;

      if (result != null) {
        if (isPassed) {
          if (result['refundResult'] != null && result['refundResult']['success'] == true) {
            final refData = result['refundResult'];
            final amt = refData['amount'] ?? 0;
            final refId = refData['refundId'] ?? '';
            KaapavToast.success(
              context,
              'QC Passed! Razorpay auto-refund of ₹$amt processed (${refId.isNotEmpty ? refId : 'Success'}). WhatsApp sent.',
            );
          } else if (result['isCod'] == true) {
            KaapavToast.success(
              context,
              'QC Passed! COD order marked for manual bank/UPI refund.',
            );
          } else {
            KaapavToast.success(
              context,
              'Quality inspection passed. WhatsApp notification sent.',
            );
          }
        } else {
          KaapavToast.success(
            context,
            'Quality inspection failed. Customer notified on WhatsApp.',
          );
        }

        await _loadReturnRequests();
        await _loadEvents();
      } else {
        final providerError = ref.read(orderProvider).error;
        KaapavToast.error(
          context,
          providerError ?? 'Failed to complete quality inspection',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _reviewingReturnRequestId = null;
        });
      }
    }
  }

  Future<void> _processReturnRefund(
    Map<String, dynamic> returnRequest,
  ) async {
    if (_reviewingReturnRequestId != null) {
      return;
    }

    final requestId = (returnRequest['request_id'] ?? '').toString().trim();

    if (requestId.isEmpty) {
      KaapavToast.error(
        context,
        'Return request ID is missing',
      );
      return;
    }

    var deductFee = false;

    final noteController = TextEditingController();

    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Prepare Razorpay refund',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The exact refundable amount will be calculated by the server using the returned items and allocated order discount.',
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      value: deductFee,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Deduct ₹60 reverse-shipping fee',
                      ),
                      subtitle: const Text(
                        'Leave unchecked to refund without the ₹60 deduction.',
                      ),
                      onChanged: (value) {
                        setDialogState(
                          () {
                            deductFee = value == true;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Owner note (optional)',
                        hintText: 'Example: QC approved and refund confirmed',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      {
                        'deductFee': deductFee,
                        'ownerNote': noteController.text.trim(),
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.calculate_outlined,
                  ),
                  label: const Text(
                    'Preview Refund',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final ownerNote = noteController.text.trim();

    noteController.dispose();

    if (options == null || !mounted) {
      return;
    }

    deductFee = options['deductFee'] == true;

    setState(
      () {
        _reviewingReturnRequestId = requestId;
      },
    );

    double numberValue(
      dynamic value,
    ) {
      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    try {
      final preview = await ref
          .read(
            orderProvider.notifier,
          )
          .processOrderReturnRefund(
            widget.orderId,
            requestId,
            deductReverseShippingFee: deductFee,
            previewOnly: true,
            ownerNote: ownerNote,
          );

      if (!mounted) return;

      if (preview == null) {
        KaapavToast.error(
          context,
          ref.read(orderProvider).error ?? 'Failed to calculate refund',
        );
        return;
      }

      final selectedGross = numberValue(
        preview['selectedGross'],
      );

      final allocatedDiscount = numberValue(
        preview['allocatedDiscount'],
      );

      final refundableItemValue = numberValue(
        preview['refundableItemValue'],
      );

      final deductionAmount = numberValue(
        preview['deductionAmount'],
      );

      final refundAmount = numberValue(
        preview['amount'],
      );

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Confirm Razorpay refund',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review the final amount carefully. Confirming will send the refund to the original Razorpay payment method.',
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Returned-item value: '
                    '₹${selectedGross.toStringAsFixed(2)}',
                  ),
                  if (allocatedDiscount > 0) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Allocated order discount: '
                      '-₹${allocatedDiscount.toStringAsFixed(2)}',
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Refundable item value: '
                    '₹${refundableItemValue.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reverse-shipping deduction: '
                    '-₹${deductionAmount.toStringAsFixed(2)}',
                  ),
                  const Divider(
                    height: 28,
                  ),
                  Text(
                    'Final refund: '
                    '₹${refundAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'This action can create a real Razorpay refund. Do not confirm unless the amount and return request are correct.',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text(
                  'Cancel',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                icon: const Icon(
                  Icons.currency_rupee,
                ),
                label: Text(
                  'Refund ₹${refundAmount.toStringAsFixed(2)}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF10B981,
                  ),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }

      final result = await ref
          .read(
            orderProvider.notifier,
          )
          .processOrderReturnRefund(
            widget.orderId,
            requestId,
            deductReverseShippingFee: deductFee,
            ownerNote: ownerNote,
          );

      if (!mounted) return;

      if (result == null) {
        KaapavToast.error(
          context,
          ref.read(orderProvider).error ?? 'Razorpay refund failed',
        );
        return;
      }

      final refundStatus = (result['refundStatus'] ?? '').toString();

      final processedAmount = numberValue(
        result['amount'],
      );

      KaapavToast.success(
        context,
        refundStatus == 'processed'
            ? 'Refund of ₹${processedAmount.toStringAsFixed(2)} processed.'
            : 'Refund of ₹${processedAmount.toStringAsFixed(2)} initiated.',
      );

      await _loadReturnRequests();
      await _loadEvents();
      await _ensureOrderLoaded();
    } finally {
      if (mounted) {
        setState(
          () {
            _reviewingReturnRequestId = null;
          },
        );
      }
    }
  }

  String _formatReturnLabel(
    dynamic value,
  ) {
    final text = (value ?? '').toString().trim().replaceAll('_', ' ');

    if (text.isEmpty) {
      return '-';
    }

    return text
        .split(' ')
        .where(
          (part) => part.isNotEmpty,
        )
        .map(
          (part) => '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  Color _returnStatusColor(
    String status,
  ) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);

      case 'rejected':
        return const Color(0xFFEF4444);

      case 'requested':
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildReturnRequestsCard(
    bool isDark,
  ) {
    final backgroundColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;

    final borderColor = isDark
        ? Colors.white.withValues(
            alpha: 0.06,
          )
        : const Color(0xFFE5E7EB);

    if (_isLoadingReturnRequests) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: KaapavTheme.gold,
          ),
        ),
      );
    }

    if (_returnRequests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.assignment_return_outlined,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No return or exchange requests for this order.',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh requests',
              onPressed: _loadReturnRequests,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _returnRequests.map(
        (returnRequest) {
          final requestId = (returnRequest['request_id'] ?? '').toString();

          final status =
              (returnRequest['status'] ?? 'requested').toString().toLowerCase();

          final statusColor = _returnStatusColor(
            status,
          );

          final requestType = _formatReturnLabel(
            returnRequest['request_type'],
          );

          final requestScope = _formatReturnLabel(
            returnRequest['request_scope'],
          );

          final reasonText =
              (returnRequest['reason_text'] ?? '').toString().trim();

          final customerNote =
              (returnRequest['customer_note'] ?? '').toString().trim();

          final ownerNote =
              (returnRequest['owner_note'] ?? '').toString().trim();

          final requestedAt = (returnRequest['requested_at'] ??
                  returnRequest['created_at'] ??
                  '')
              .toString();

          final rawItems = returnRequest['items'];

          final itemCount = rawItems is List ? rawItems.length : 0;

          final canReview = status == 'requested';

          final canSchedulePickup = status == 'approved';

          final canMarkPickedUp = status == 'pickup_scheduled';

          final canMarkReceived = status == 'picked_up';

          final canReviewQc = status == 'received';

          final requestTypeKey =
              (returnRequest['request_type'] ?? '').toString().toLowerCase();

          final refundStatus = (returnRequest['refund_status'] ?? 'not_started')
              .toString()
              .toLowerCase();

          final canProcessRefund = requestTypeKey == 'return' &&
              status == 'qc_passed' &&
              refundStatus != 'processing' &&
              refundStatus != 'pending' &&
              refundStatus != 'processed';

          final isReviewing = _reviewingReturnRequestId == requestId;

          final reviewLocked = _reviewingReturnRequestId != null;

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(
              bottom: 10,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      requestType.toLowerCase() == 'exchange'
                          ? Icons.swap_horiz_rounded
                          : Icons.assignment_return_outlined,
                      color: statusColor,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        '$requestType Request',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatReturnLabel(
                          status,
                        ),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                _buildReturnProgressStepper(status, requestTypeKey),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Request ID: $requestId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scope: $requestScope',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                if (itemCount > 0) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Selected items: $itemCount',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
                if (requestedAt.isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Requested: ${_formatDate(requestedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (reasonText.isNotEmpty) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Reason: $reasonText',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
                if (customerNote.isNotEmpty) ...[
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Customer note: $customerNote',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
                if (ownerNote.isNotEmpty) ...[
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Owner note: $ownerNote',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                () {
                  final returnCourier = (returnRequest['return_courier'] ?? '').toString().trim();
                  final returnAwb = (returnRequest['return_awb_number'] ?? '').toString().trim();
                  final returnTrackUrl = (returnRequest['return_tracking_url'] ?? '').toString().trim();
                  final pickupScheduledDate = (returnRequest['pickup_scheduled_date'] ?? '').toString().trim();

                  if (returnCourier.isEmpty && returnAwb.isEmpty && pickupScheduledDate.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF7C3AED)),
                            SizedBox(width: 6),
                            Text(
                              'Reverse Logistics Tracking',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (returnCourier.isNotEmpty)
                          Text('Courier: $returnCourier', style: const TextStyle(fontSize: 12)),
                        if (returnAwb.isNotEmpty)
                          Text('AWB: $returnAwb', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        if (pickupScheduledDate.isNotEmpty)
                          Text('Pickup Date: $pickupScheduledDate', style: const TextStyle(fontSize: 12)),
                        if (returnTrackUrl.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final uri = Uri.tryParse(returnTrackUrl);
                              if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            child: Text(
                              'Track Return Package ➔',
                              style: TextStyle(
                                fontSize: 11,
                                color: KaapavTheme.gold,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }(),
                () {
                  final refundAmount = double.tryParse((returnRequest['refund_amount'] ?? '').toString()) ?? 0;
                  final refundId = (returnRequest['refund_id'] ?? '').toString().trim();
                  final acquirerRef = (returnRequest['refund_acquirer_reference'] ?? '').toString().trim();
                  final reverseFee = double.tryParse((returnRequest['reverse_shipping_fee'] ?? '').toString()) ?? 0;

                  if (refundAmount <= 0 && refundId.isEmpty && refundStatus != 'processed' && refundStatus != 'pending' && refundStatus != 'processing' && refundStatus != 'manual_pending') {
                    return const SizedBox.shrink();
                  }

                  final isProcessed = refundStatus == 'processed' || status == 'refunded';
                  final isFailed = refundStatus == 'failed';
                  final isManual = refundStatus == 'manual_pending';

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isFailed
                          ? (isDark ? const Color(0xFF3B1F1F) : const Color(0xFFFEF2F2))
                          : isManual
                              ? (isDark ? const Color(0xFF3B2F1F) : const Color(0xFFFFFBEB))
                              : (isDark ? const Color(0xFF1E3A2B) : const Color(0xFFF0FDF4)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFailed
                            ? const Color(0xFFFCA5A5)
                            : isManual
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isFailed
                                  ? Icons.error_outline
                                  : isManual
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.check_circle_outline,
                              size: 16,
                              color: isFailed
                                  ? const Color(0xFFEF4444)
                                  : isManual
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isProcessed
                                  ? 'Refund Processed'
                                  : isFailed
                                      ? 'Refund Failed'
                                      : isManual
                                          ? 'Manual COD Refund Pending'
                                          : 'Refund Initiated',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: isFailed
                                    ? const Color(0xFFEF4444)
                                    : isManual
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (refundAmount > 0)
                          Text(
                            'Refund Amount: ₹${refundAmount.toStringAsFixed(2)}${reverseFee > 0 ? ' (₹${reverseFee.toStringAsFixed(0)} reverse fee deducted)' : ''}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        if (refundId.isNotEmpty)
                          Text('Razorpay Refund ID: $refundId', style: const TextStyle(fontSize: 11)),
                        if (acquirerRef.isNotEmpty)
                          Text('Bank Ref (ARN/RRN/UTR): $acquirerRef', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }(),
                if (canReview) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: reviewLocked
                              ? null
                              : () {
                                  _reviewReturnRequest(
                                    returnRequest,
                                    'rejected',
                                  );
                                },
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                          label: Text(
                            isReviewing ? 'Saving...' : 'Reject',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(
                              0xFFEF4444,
                            ),
                            side: const BorderSide(
                              color: Color(
                                0xFFEF4444,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: reviewLocked
                              ? null
                              : () {
                                  _reviewReturnRequest(
                                    returnRequest,
                                    'approved',
                                  );
                                },
                          icon: isReviewing
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_rounded,
                                ),
                          label: Text(
                            isReviewing ? 'Saving...' : 'Approve',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF10B981,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (canSchedulePickup) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: reviewLocked
                          ? null
                          : () {
                              _scheduleReturnPickup(
                                returnRequest,
                              );
                            },
                      icon: isReviewing
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.local_shipping_outlined,
                            ),
                      label: Text(
                        isReviewing ? 'Saving...' : 'Mark Pickup Scheduled',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF7C3AED,
                        ),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (canMarkPickedUp) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: reviewLocked
                          ? null
                          : () {
                              _markReturnPickedUp(
                                returnRequest,
                              );
                            },
                      icon: isReviewing
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                            ),
                      label: Text(
                        isReviewing ? 'Saving...' : 'Confirm Package Picked Up',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF2563EB,
                        ),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (canMarkReceived) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: reviewLocked
                          ? null
                          : () {
                              _markReturnReceived(
                                returnRequest,
                              );
                            },
                      icon: isReviewing
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.move_to_inbox_outlined,
                            ),
                      label: Text(
                        isReviewing ? 'Saving...' : 'Confirm Package Received',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF0F766E,
                        ),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (canReviewQc) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: reviewLocked
                              ? null
                              : () {
                                  _reviewReturnQc(
                                    returnRequest,
                                    'passed',
                                  );
                                },
                          icon: const Icon(
                            Icons.verified_outlined,
                          ),
                          label: Text(
                            isReviewing ? 'Saving...' : 'QC Pass',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: reviewLocked
                              ? null
                              : () {
                                  _reviewReturnQc(
                                    returnRequest,
                                    'failed',
                                  );
                                },
                          icon: const Icon(
                            Icons.report_problem_outlined,
                          ),
                          label: const Text(
                            'QC Fail',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(
                              0xFFEF4444,
                            ),
                            side: const BorderSide(
                              color: Color(
                                0xFFEF4444,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (canProcessRefund) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: reviewLocked
                          ? null
                          : () {
                              _processReturnRefund(
                                returnRequest,
                              );
                            },
                      icon: isReviewing
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.currency_rupee,
                            ),
                      label: Text(
                        isReviewing
                            ? 'Processing...'
                            : refundStatus == 'failed'
                                ? 'Retry Razorpay Refund'
                                : 'Process Razorpay Refund',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF10B981,
                        ),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildReturnProgressStepper(String status, String requestType) {
    final isReturn = requestType != 'exchange';
    final steps = [
      'Requested',
      'Approved',
      'Pickup',
      'QC Pass',
      isReturn ? 'Refunded' : 'Completed',
    ];

    int activeIdx = 0;
    if (status == 'requested') {
      activeIdx = 0;
    } else if (status == 'approved') {
      activeIdx = 1;
    } else if (status == 'pickup_scheduled' || status == 'picked_up') {
      activeIdx = 2;
    } else if (status == 'received' || status == 'qc_passed') {
      activeIdx = 3;
    } else if (status == 'refund_pending' ||
        status == 'refunded' ||
        status == 'completed') {
      activeIdx = 4;
    } else if (status == 'rejected' || status == 'qc_failed') {
      activeIdx = -1;
    }

    final isFailed = status == 'rejected' || status == 'qc_failed';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final isDone = !isFailed && stepIdx < activeIdx;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE5E7EB),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isDone = !isFailed && stepIdx < activeIdx;
          final isActive = !isFailed && stepIdx == activeIdx;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : isActive
                          ? KaapavTheme.gold
                          : isFailed && stepIdx == 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFE5E7EB),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: (isActive || isDone)
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                steps[stepIdx],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? KaapavTheme.gold
                      : isDone
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                ),
              ),
            ],
          );
        }),
      ),
    );
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
      final result =
          await ref.read(orderProvider.notifier).bookShiprocket(widget.orderId);

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

      final ok = await ref
          .read(orderProvider.notifier)
          .downloadInvoicePdf(orderId, path);
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
    final shippingNameCtrl = TextEditingController(
        text: order.shippingName ?? order.customerName ?? '');
    final addressCtrl =
        TextEditingController(text: order.shippingAddress ?? '');
    final cityCtrl = TextEditingController(text: order.shippingCity ?? '');
    final stateCtrl = TextEditingController(text: order.shippingState ?? '');
    final pincodeCtrl =
        TextEditingController(text: order.shippingPincode ?? '');

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
                    DropdownMenuItem(
                        value: 'refunded', child: Text('Refunded')),
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
            onPressed: () =>
                Navigator.pop(ctx, paymentIdController.text.trim()),
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

    final link = await ref
        .read(orderProvider.notifier)
        .generatePaymentLink(widget.orderId);

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
      if (order.fullShippingAddress.isNotEmpty)
        '📍 ${order.fullShippingAddress}',
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
                          final color =
                              _statusColors[status] ?? KaapavTheme.gold;
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
                    if (_canBookShiprocket(order)) ...[
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

    final products = ref.watch(productProvider).products;
    final productImageBySku = {
      for (final p in products)
        if (p.sku.isNotEmpty) p.sku: p.imageUrl ?? '',
    };

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
              if (_canBookShiprocket(order))
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
                  final sku = item['sku']?.toString().trim() ?? '';

                  return _OrderItemRow(
                    item: item,
                    isLast: isLast,
                    isDark: isDark,
                    fallbackImageUrl: productImageBySku[sku] ?? '',
                    onTap: () {
                      if (sku.isEmpty) {
                        KaapavToast.error(context, 'Product SKU missing');
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(sku: sku),
                        ),
                      );
                    },
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
                _InfoRowData('Payment ID', order.paymentId ?? '',
                    copyable: true),
              if ((order.paymentLink ?? '').isNotEmpty)
                _InfoRowData('Payment Link', order.paymentLink ?? '',
                    copyable: true),
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
                  _InfoRowData('Track', order.trackingUrl ?? '',
                      copyable: true),
              ],
            ),
            const SizedBox(height: 12),
          ],

          _SectionHeader(
            title: 'Return & Refund Requests',
            icon: Icons.assignment_return_outlined,
          ),
          const SizedBox(height: 8),
          _buildReturnRequestsCard(isDark),
          const SizedBox(height: 12),

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
                label:
                    const Text('Download PDF', style: TextStyle(fontSize: 12)),
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
                label: const Text('Send to Customer',
                    style: TextStyle(fontSize: 12)),
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
                  onPressed: order.hasTracking
                      ? () => _resendWhatsApp('shipped')
                      : null,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      color:
                          filled ? KaapavTheme.gold : const Color(0xFFE5E7EB),
                    ),
                  );
                }

                final idx = i ~/ 2;
                final done = idx <= currentIdx;
                final active = idx == currentIdx;
                final color = done ? KaapavTheme.gold : const Color(0xFFD1D5DB);

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
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color:
                            active ? KaapavTheme.gold : const Color(0xFF9CA3AF),
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
  final String fallbackImageUrl;
  final VoidCallback? onTap;

  const _OrderItemRow({
    required this.item,
    required this.isLast,
    required this.isDark,
    this.fallbackImageUrl = '',
    this.onTap,
  });

  String _text(dynamic value) => value?.toString().trim() ?? '';

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _qty(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  List<String> _images() {
    final urls = <String>[];

    void add(dynamic value) {
      final url = _text(value);
      if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
    }

    add(item['product_image_url']);
    add(item['image_url']);
    add(item['image']);
    add(fallbackImageUrl);

    final productImages = item['product_images'];
    if (productImages is List) {
      for (final img in productImages) {
        add(img);
      }
    }

    return urls;
  }

  void _openImagePreview(
      BuildContext context, List<String> images, String name) {
    if (images.isEmpty) {
      KaapavToast.error(context, 'Product image not available');
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: images.length,
                itemBuilder: (_, index) {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: KaapavTheme.gold,
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 42,
                left: 16,
                right: 56,
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                top: 36,
                right: 12,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 28,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${images.length} images • swipe',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        _text(item['name']).isNotEmpty ? _text(item['name']) : 'Product';
    final category = _text(item['category']);
    final sku = _text(item['sku']);
    final qty = _qty(item['qty'] ?? item['quantity']);
    final price = _num(item['price']);
    final images = _images();
    final rawImageUrl = item['image_url']?.toString().trim() ??
        item['image']?.toString().trim() ??
        item['imageUrl']?.toString().trim() ??
        item['thumbnail']?.toString().trim() ??
        item['product_image']?.toString().trim() ??
        '';

    final imageUrl = rawImageUrl.isNotEmpty ? rawImageUrl : fallbackImageUrl;
    final lineTotal = price * qty;

    return InkWell(
      onTap: onTap,
      onLongPress: sku.isEmpty
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: sku));
              KaapavToast.success(context, 'SKU copied: $sku');
            },
      child: Container(
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
            GestureDetector(
              onTap: () => _openImagePreview(context, images, name),
              child: Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFF5F0E8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: Icon(
                                Icons.diamond_outlined,
                                size: 22,
                                color: Color(0xFFC49432),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.diamond_outlined,
                                size: 22,
                                color: Color(0xFFC49432),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.diamond_outlined,
                              size: 22,
                              color: Color(0xFFC49432),
                            ),
                          ),
                  ),
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ],
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
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (sku.isNotEmpty)
                    Text(
                      'SKU: $sku',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC49432),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '₹${price.toStringAsFixed(0)} × $qty • Tap image for packing',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${lineTotal.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
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
        crossAxisAlignment: row.multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
