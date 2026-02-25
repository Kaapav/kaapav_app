class Validators {
  Validators._();

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Invalid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 10 || clean.length > 12) return 'Invalid phone number';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.trim().isEmpty) return 'PIN is required';
    if (value.length < 4 || value.length > 6) return 'PIN must be 4-6 digits';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN must be digits only';
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Invalid pincode';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Invalid price';
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) return 'Stock is required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Invalid stock';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? sku(String? value) {
    if (value == null || value.trim().isEmpty) return 'SKU is required';
    if (value.trim().length < 2) return 'SKU too short';
    return null;
  }

  static String? couponCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Coupon code is required';
    if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(value.trim().toUpperCase())) {
      return 'Invalid coupon code format';
    }
    return null;
  }

  static bool isValidOrderId(String? value) {
    if (value == null) return false;
    return RegExp(r'^KP-?\d{4,}$', caseSensitive: false).hasMatch(value.trim());
  }

  static bool isValidPhone(String? value) {
    if (value == null) return false;
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 10 && clean.length <= 12;
  }
}