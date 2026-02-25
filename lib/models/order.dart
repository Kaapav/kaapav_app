class Order {
  final int? id;
  final String orderId;
  final String phone;
  final String? customerName;
  final List<dynamic> items;
  final int itemCount;
  final double subtotal;
  final double discount;
  final String? discountCode;
  final double shippingCost;
  final double tax;
  final double total;
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPincode;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? paymentId;
  final String? paymentLink;
  final String? paymentLinkExpires;
  final String? paidAt;
  final String? courier;
  final String? trackingId;
  final String? trackingUrl;
  final String? shipmentId;
  final String? awbNumber;
  final String? confirmedAt;
  final String? shippedAt;
  final String? deliveredAt;
  final String? cancelledAt;
  final String? customerNotes;
  final String? internalNotes;
  final String? cancellationReason;
  final String source;
  final bool confirmationSent;
  final bool shippingSent;
  final bool deliverySent;
  final bool reviewSent;
  final String? createdAt;
  final String? updatedAt;

  const Order({
    this.id,
    this.orderId = '',
    this.phone = '',
    this.customerName,
    this.items = const [],
    this.itemCount = 0,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.discountCode,
    this.shippingCost = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress,
    this.shippingCity,
    this.shippingState,
    this.shippingPincode,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paymentId,
    this.paymentLink,
    this.paymentLinkExpires,
    this.paidAt,
    this.courier,
    this.trackingId,
    this.trackingUrl,
    this.shipmentId,
    this.awbNumber,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.customerNotes,
    this.internalNotes,
    this.cancellationReason,
    this.source = 'whatsapp',
    this.confirmationSent = false,
    this.shippingSent = false,
    this.deliverySent = false,
    this.reviewSent = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      orderId: json['order_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      customerName: json['customer_name'] as String?,
      items: _parseDynamicList(json['items']),
      itemCount: _toInt(json['item_count']),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      discountCode: json['discount_code'] as String?,
      shippingCost: _toDouble(json['shipping_cost']),
      tax: _toDouble(json['tax']),
      total: _toDouble(json['total']),
      shippingName: json['shipping_name'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingState: json['shipping_state'] as String?,
      shippingPincode: json['shipping_pincode'] as String?,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      paymentMethod: json['payment_method'] as String?,
      paymentId: json['payment_id'] as String?,
      paymentLink: json['payment_link'] as String?,
      paymentLinkExpires: json['payment_link_expires'] as String?,
      paidAt: json['paid_at'] as String?,
      courier: json['courier'] as String?,
      trackingId: json['tracking_id'] as String?,
      trackingUrl: json['tracking_url'] as String?,
      shipmentId: json['shipment_id'] as String?,
      awbNumber: json['awb_number'] as String?,
      confirmedAt: json['confirmed_at'] as String?,
      shippedAt: json['shipped_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      customerNotes: json['customer_notes'] as String?,
      internalNotes: json['internal_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      source: json['source'] as String? ?? 'whatsapp',
      confirmationSent: json['confirmation_sent'] == 1 ||
          json['confirmation_sent'] == true,
      shippingSent:
          json['shipping_sent'] == 1 || json['shipping_sent'] == true,
      deliverySent:
          json['delivery_sent'] == 1 || json['delivery_sent'] == true,
      reviewSent:
          json['review_sent'] == 1 || json['review_sent'] == true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'phone': phone,
        'customer_name': customerName,
        'items': items,
        'item_count': itemCount,
        'subtotal': subtotal,
        'discount': discount,
        'discount_code': discountCode,
        'shipping_cost': shippingCost,
        'tax': tax,
        'total': total,
        'shipping_name': shippingName,
        'shipping_phone': shippingPhone,
        'shipping_address': shippingAddress,
        'shipping_city': shippingCity,
        'shipping_state': shippingState,
        'shipping_pincode': shippingPincode,
        'status': status,
        'payment_status': paymentStatus,
        'payment_method': paymentMethod,
        'payment_id': paymentId,
        'payment_link': paymentLink,
        'payment_link_expires': paymentLinkExpires,
        'paid_at': paidAt,
        'courier': courier,
        'tracking_id': trackingId,
        'tracking_url': trackingUrl,
        'shipment_id': shipmentId,
        'awb_number': awbNumber,
        'confirmed_at': confirmedAt,
        'shipped_at': shippedAt,
        'delivered_at': deliveredAt,
        'cancelled_at': cancelledAt,
        'customer_notes': customerNotes,
        'internal_notes': internalNotes,
        'cancellation_reason': cancellationReason,
        'source': source,
        'confirmation_sent': confirmationSent ? 1 : 0,
        'shipping_sent': shippingSent ? 1 : 0,
        'delivery_sent': deliverySent ? 1 : 0,
        'review_sent': reviewSent ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Order copyWith({
    int? id,
    String? orderId,
    String? phone,
    String? customerName,
    List<dynamic>? items,
    int? itemCount,
    double? subtotal,
    double? discount,
    String? discountCode,
    double? shippingCost,
    double? tax,
    double? total,
    String? shippingName,
    String? shippingPhone,
    String? shippingAddress,
    String? shippingCity,
    String? shippingState,
    String? shippingPincode,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentId,
    String? paymentLink,
    String? paymentLinkExpires,
    String? paidAt,
    String? courier,
    String? trackingId,
    String? trackingUrl,
    String? shipmentId,
    String? awbNumber,
    String? confirmedAt,
    String? shippedAt,
    String? deliveredAt,
    String? cancelledAt,
    String? customerNotes,
    String? internalNotes,
    String? cancellationReason,
    String? source,
    bool? confirmationSent,
    bool? shippingSent,
    bool? deliverySent,
    bool? reviewSent,
    String? createdAt,
    String? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      phone: phone ?? this.phone,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountCode: discountCode ?? this.discountCode,
      shippingCost: shippingCost ?? this.shippingCost,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      shippingName: shippingName ?? this.shippingName,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingPincode: shippingPincode ?? this.shippingPincode,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      paymentLink: paymentLink ?? this.paymentLink,
      paymentLinkExpires: paymentLinkExpires ?? this.paymentLinkExpires,
      paidAt: paidAt ?? this.paidAt,
      courier: courier ?? this.courier,
      trackingId: trackingId ?? this.trackingId,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      shipmentId: shipmentId ?? this.shipmentId,
      awbNumber: awbNumber ?? this.awbNumber,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      customerNotes: customerNotes ?? this.customerNotes,
      internalNotes: internalNotes ?? this.internalNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      source: source ?? this.source,
      confirmationSent: confirmationSent ?? this.confirmationSent,
      shippingSent: shippingSent ?? this.shippingSent,
      deliverySent: deliverySent ?? this.deliverySent,
      reviewSent: reviewSent ?? this.reviewSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Convenience getters ──
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid => paymentStatus == 'paid';
  bool get isUnpaid => paymentStatus == 'unpaid';
  bool get isRefunded => paymentStatus == 'refunded';
  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get canShip => status == 'confirmed' || status == 'processing';
  bool get hasTracking => awbNumber != null && awbNumber!.isNotEmpty;

  String get statusEmoji {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'confirmed':
        return '✅';
      case 'processing':
        return '⚙️';
      case 'shipped':
        return '🚚';
      case 'delivered':
        return '📦';
      case 'cancelled':
        return '❌';
      case 'returned':
        return '↩️';
      default:
        return '📋';
    }
  }

  String get fullShippingAddress {
    final parts = <String>[];
    if (shippingAddress != null) parts.add(shippingAddress!);
    if (shippingCity != null) parts.add(shippingCity!);
    if (shippingState != null) parts.add(shippingState!);
    if (shippingPincode != null) parts.add(shippingPincode!);
    return parts.join(', ');
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static List<dynamic> _parseDynamicList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val;
    return [];
  }
}