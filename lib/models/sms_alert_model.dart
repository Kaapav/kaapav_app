// lib/models/sms_alert_model.dart

class SmsAlert {
  final String id;
  final String type; // 'otp' | 'payment' | 'shipping' | 'general'
  final String sender;
  final String title;
  final String body;
  final String? otp;
  final double? amount;
  final String? referenceId; // Payment ID or AWB or Order ID
  final String? trackingUrl;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final bool isRead;

  const SmsAlert({
    required this.id,
    required this.type,
    required this.sender,
    required this.title,
    required this.body,
    this.otp,
    this.amount,
    this.referenceId,
    this.trackingUrl,
    required this.timestamp,
    this.expiresAt,
    this.isRead = false,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get remainingTime {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  SmsAlert copyWith({
    String? id,
    String? type,
    String? sender,
    String? title,
    String? body,
    String? otp,
    double? amount,
    String? referenceId,
    String? trackingUrl,
    DateTime? timestamp,
    DateTime? expiresAt,
    bool? isRead,
  }) {
    return SmsAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      title: title ?? this.title,
      body: body ?? this.body,
      otp: otp ?? this.otp,
      amount: amount ?? this.amount,
      referenceId: referenceId ?? this.referenceId,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'sender': sender,
      'title': title,
      'body': body,
      'otp': otp,
      'amount': amount,
      'referenceId': referenceId,
      'trackingUrl': trackingUrl,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory SmsAlert.fromJson(Map<String, dynamic> json) {
    return SmsAlert(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      sender: json['sender'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      otp: json['otp'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      referenceId: json['referenceId'] as String?,
      trackingUrl: json['trackingUrl'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
