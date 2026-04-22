import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _inrFormat = NumberFormat('#,##,##0', 'en_IN');
  static final _inrDecimalFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateTimeFormat = DateFormat('d MMM yyyy, h:mm a');

  static String inr(dynamic amount) {
    if (amount == null) return '₹0';
    final value = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0;
    if (value == value.roundToDouble()) {
      return '₹${_inrFormat.format(value.toInt())}';
    }
    return '₹${_inrDecimalFormat.format(value)}';
  }

  static String date(DateTime? dt) {
    if (dt == null) return '';
    return _dateFormat.format(dt);
  }

  static String time(DateTime? dt) {
    if (dt == null) return '';
    return _timeFormat.format(dt);
  }

  static String dateTime(DateTime? dt) {
    if (dt == null) return '';
    return _dateTimeFormat.format(dt);
  }

  static DateTime? parseDate(String? str) {
  if (str == null || str.isEmpty) return null;
  try {
    // Handle Unix epoch (stored as string e.g. "1713600000" or "1713600000000")
    final asInt = int.tryParse(str);
    if (asInt != null) {
      final ms = asInt > 9999999999 ? asInt : asInt * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }

    final dt = DateTime.parse(str);

    // If string has no timezone info (no Z, no +XX:XX) → assume UTC
    final hasTimezone = str.endsWith('Z') ||
        str.contains('+') ||
        RegExp(r'-\d{2}:\d{2}$').hasMatch(str);

    if (!hasTimezone) {
      // Reinterpret as UTC then convert to local (IST = UTC+5:30)
      return DateTime.utc(
        dt.year, dt.month, dt.day,
        dt.hour, dt.minute, dt.second, dt.millisecond,
      ).toLocal();
    }

    return dt.toLocal();
  } catch (_) {
    return null;
  }
}

  static String fileSize(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  static String duration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  static String percent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  static String orderId(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    if (id.startsWith('KP-')) return id;
    return 'KP-$id';
  }
}