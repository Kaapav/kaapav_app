class Payment {
  final int? id;
  final String paymentId;
  final String? orderId;
  final String phone;
  final String gateway;
  final String? gatewayPaymentId;
  final String? gatewayOrderId;
  final String? gatewaySignature;
  final double amount;
  final String currency;
  final String status;
  final String? method;
  final String? paidAt;
  final String? failedAt;
  final double? refundAmount;
  final String? refundId;
  final String? refundedAt;
  final String? createdAt;

  const Payment({
    this.id,
    this.paymentId = '',
    this.orderId,
    this.phone = '',
    this.gateway = 'razorpay',
    this.gatewayPaymentId,
    this.gatewayOrderId,
    this.gatewaySignature,
    this.amount = 0.0,
    this.currency = 'INR',
    this.status = 'pending',
    this.method,
    this.paidAt,
    this.failedAt,
    this.refundAmount,
    this.refundId,
    this.refundedAt,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int?,
      paymentId: json['payment_id'] as String? ?? '',
      orderId: json['order_id'] as String?,
      phone: json['phone'] as String? ?? '',
      gateway: json['gateway'] as String? ?? 'razorpay',
      gatewayPaymentId: json['gateway_payment_id'] as String?,
      gatewayOrderId: json['gateway_order_id'] as String?,
      gatewaySignature: json['gateway_signature'] as String?,
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'pending',
      method: json['method'] as String?,
      paidAt: json['paid_at'] as String?,
      failedAt: json['failed_at'] as String?,
      refundAmount: json['refund_amount'] != null
          ? _toDouble(json['refund_amount'])
          : null,
      refundId: json['refund_id'] as String?,
      refundedAt: json['refunded_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payment_id': paymentId,
        'order_id': orderId,
        'phone': phone,
        'gateway': gateway,
        'gateway_payment_id': gatewayPaymentId,
        'gateway_order_id': gatewayOrderId,
        'gateway_signature': gatewaySignature,
        'amount': amount,
        'currency': currency,
        'status': status,
        'method': method,
        'paid_at': paidAt,
        'failed_at': failedAt,
        'refund_amount': refundAmount,
        'refund_id': refundId,
        'refunded_at': refundedAt,
        'created_at': createdAt,
      };

  Payment copyWith({
    int? id,
    String? paymentId,
    String? orderId,
    String? phone,
    String? gateway,
    String? gatewayPaymentId,
    String? gatewayOrderId,
    String? gatewaySignature,
    double? amount,
    String? currency,
    String? status,
    String? method,
    String? paidAt,
    String? failedAt,
    double? refundAmount,
    String? refundId,
    String? refundedAt,
    String? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      phone: phone ?? this.phone,
      gateway: gateway ?? this.gateway,
      gatewayPaymentId: gatewayPaymentId ?? this.gatewayPaymentId,
      gatewayOrderId: gatewayOrderId ?? this.gatewayOrderId,
      gatewaySignature: gatewaySignature ?? this.gatewaySignature,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      method: method ?? this.method,
      paidAt: paidAt ?? this.paidAt,
      failedAt: failedAt ?? this.failedAt,
      refundAmount: refundAmount ?? this.refundAmount,
      refundId: refundId ?? this.refundId,
      refundedAt: refundedAt ?? this.refundedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';

  static double _toDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}