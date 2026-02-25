import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  /// Format timestamp to time string (10:30 AM)
  static String formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Format timestamp to date string (12 Feb 2026)
  static String formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Format timestamp to date + time (12 Feb, 10:30 AM)
  static String formatDateTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('d MMM, h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Format timestamp to relative time (2 min ago, Yesterday, etc)
  static String formatRelativeTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';

      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(dt.year, dt.month, dt.day);

      if (messageDay == today) return DateFormat('h:mm a').format(dt);
      if (messageDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
      if (diff.inDays < 7) return DateFormat('EEEE').format(dt);

      return DateFormat('d/M/yy').format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Format chat list timestamp (WhatsApp style)
  static String formatChatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(dt.year, dt.month, dt.day);

      if (messageDay == today) return DateFormat('h:mm a').format(dt);
      if (messageDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
      if (now.difference(dt).inDays < 7) return DateFormat('EEE').format(dt);

      return DateFormat('d/M/yy').format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Format currency (₹1,299)
  static String formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    try {
      final value = amount is String ? double.parse(amount) : (amount as num).toDouble();
      final formatter = NumberFormat('#,##,##0', 'en_IN');
      if (value == value.roundToDouble()) {
        return '₹${formatter.format(value.toInt())}';
      }
      return '₹${formatter.format(value)}';
    } catch (_) {
      return '₹0';
    }
  }

  /// Format large numbers (1.2K, 3.5L)
  static String formatCount(int count) {
    if (count >= 10000000) return '${(count / 10000000).toStringAsFixed(1)}Cr';
    if (count >= 100000) return '${(count / 100000).toStringAsFixed(1)}L';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  /// Format phone number (91XXXXXXXXXX → +91 XXXXX XXXXX)
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 12 && clean.startsWith('91')) {
      return '+91 ${clean.substring(2, 7)} ${clean.substring(7)}';
    }
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return phone;
  }

  /// Truncate text with ellipsis
  static String truncate(String? text, {int maxLength = 50}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get initials from name (Kawshik → K, Kawshik M → KM)
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Get message type icon
  static String getMessageTypeIcon(String? type) {
    switch (type) {
      case 'image': return '📷';
      case 'video': return '🎥';
      case 'audio': return '🎵';
      case 'voice': return '🎤';
      case 'document': return '📄';
      case 'sticker': return '🎭';
      case 'location': return '📍';
      case 'contacts': return '👤';
      case 'order': return '🛒';
      case 'buttons': return '📱';
      case 'interactive': return '📱';
      case 'list': return '📋';
      case 'template': return '📝';
      default: return '';
    }
  }

  /// Get order status display text
  static String getOrderStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return '⏳ Pending';
      case 'confirmed': return '✅ Confirmed';
      case 'processing': return '⚙️ Processing';
      case 'shipped': return '🚚 Shipped';
      case 'delivered': return '📦 Delivered';
      case 'cancelled': return '❌ Cancelled';
      case 'returned': return '↩️ Returned';
      default: return '📋 ${status ?? "Unknown"}';
    }
  }

  /// Get payment status display text
  static String getPaymentStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'unpaid': return '❌ Unpaid';
      case 'paid': return '✅ Paid';
      case 'refunded': return '↩️ Refunded';
      default: return status ?? 'Unknown';
    }
  }

  /// Check if string is valid JSON
  static bool isJson(String? str) {
    if (str == null) return false;
    try {
      final trimmed = str.trim();
      return trimmed.startsWith('{') || trimmed.startsWith('[');
    } catch (_) {
      return false;
    }
  }

  /// Parse JSON list safely
  static List<String> parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  /// Generate unique ID
  static String generateId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecond}';
  }

  /// Mask phone number for privacy (919148XXXXXX → 9191****0016)
  static String maskPhone(String? phone) {
    if (phone == null || phone.length < 8) return phone ?? '';
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 4)}';
  }

  /// Calculate discount percentage
  static int discountPercent(double? price, double? comparePrice) {
    if (price == null || comparePrice == null || comparePrice <= price) return 0;
    return ((1 - price / comparePrice) * 100).round();
  }
}