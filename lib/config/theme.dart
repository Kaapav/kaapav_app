import 'package:flutter/material.dart';

class KaapavTheme {
  KaapavTheme._();

  // ═══════════════════════════════════════════
  // PRIMARY GOLD COLORS
  // ═══════════════════════════════════════════
  static const Color gold = Color(0xFFC49432);
  static const Color goldLight = Color(0xFFD4A84B);
  static const Color goldDark = Color(0xFFA67C28);

  // ═══════════════════════════════════════════
  // NEUTRALS
  // ═══════════════════════════════════════════
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFBF8F1);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color darkSoft = Color(0xFF374151);
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);

  // ═══════════════════════════════════════════
  // STATUS COLORS
  // ═══════════════════════════════════════════
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);

  // ═══════════════════════════════════════════
  // MESSAGE BUBBLES
  // ═══════════════════════════════════════════
  static const Color sentBubble = Color(0xFFC49432);
  static const Color receivedBubble = Color(0xFFFFFFFF);
  static const Color darkSentBubble = Color(0xFFA67C28);
  static const Color darkReceivedBubble = Color(0xFF2C2C2C);
  static const Color readBlue = Color(0xFF53BDEB);

  // ═══════════════════════════════════════════
  // LABEL COLORS
  // ═══════════════════════════════════════════
  static const Color vipLabel = Color(0xFFFFD700);
  static const Color hotLeadLabel = Color(0xFFFF6B6B);
  static const Color newLabel = Color(0xFF4ECDC4);
  static const Color returningLabel = Color(0xFF45B7D1);
  static const Color wholesaleLabel = Color(0xFF96CEB4);

  // ═══════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A84B), Color(0xFFC49432)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSentBubbleGradient = LinearGradient(
    colors: [Color(0xFFA67C28), Color(0xFF8A6820)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxShadow get goldShadow => BoxShadow(
        color: gold.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );

  // ═══════════════════════════════════════════
  // MAIN THEME GETTERS (for app.dart)
  // ═══════════════════════════════════════════
  static ThemeData get lightTheme => _lightTheme();
  static ThemeData get darkTheme => _darkTheme();

  // ═══════════════════════════════════════════
  // ORDER STATUS HELPERS
  // ═══════════════════════════════════════════
  static Color orderStatusBg(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'confirmed':
        return const Color(0xFFDBEAFE);
      case 'processing':
        return const Color(0xFFEDE9FE);
      case 'shipped':
        return const Color(0xFFCFFAFE);
      case 'delivered':
        return const Color(0xFFD1FAE5);
      case 'cancelled':
      case 'returned':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  static Color orderStatusText(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'confirmed':
        return const Color(0xFF2563EB);
      case 'processing':
        return const Color(0xFF7C3AED);
      case 'shipped':
        return const Color(0xFF0891B2);
      case 'delivered':
        return const Color(0xFF059669);
      case 'cancelled':
      case 'returned':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static IconData orderStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle;
      case 'processing':
        return Icons.settings;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.inventory_2;
      case 'cancelled':
        return Icons.cancel;
      case 'returned':
        return Icons.assignment_return;
      default:
        return Icons.help_outline;
    }
  }

  static Color paymentStatusBg(String status) {
    switch (status) {
      case 'unpaid':
        return const Color(0xFFFEE2E2);
      case 'paid':
        return const Color(0xFFD1FAE5);
      case 'refunded':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  static Color paymentStatusText(String status) {
    switch (status) {
      case 'unpaid':
        return const Color(0xFFDC2626);
      case 'paid':
        return const Color(0xFF059669);
      case 'refunded':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color labelColor(String labelName) {
    switch (labelName.toLowerCase()) {
      case 'vip':
        return vipLabel;
      case 'hot lead':
        return hotLeadLabel;
      case 'new':
        return newLabel;
      case 'returning':
        return returningLabel;
      case 'wholesale':
        return wholesaleLabel;
      default:
        return gold;
    }
  }

  // ═══════════════════════════════════════════
  // THEME DATA — LIGHT
  // ═══════════════════════════════════════════
  static ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        primary: gold,
        secondary: goldLight,
        surface: white,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: gold,
        unselectedItemColor: grayLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: gold),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: cream,
        selectedColor: gold.withOpacity(0.15),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark,
        contentTextStyle: const TextStyle(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: gold,
        unselectedLabelColor: grayLight,
        indicatorColor: gold,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // THEME DATA — DARK
  // ═══════════════════════════════════════════
  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        primary: gold,
        secondary: goldLight,
        surface: const Color(0xFF1E1E1E),
        error: error,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: gold,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: white,
      ),
      dividerTheme:
          const DividerThemeData(color: Color(0xFF333333), thickness: 1),
    );
  }
}

/// Alias — some files use KaapavColors instead of KaapavTheme
class KaapavColors {
  KaapavColors._();
  static const Color gold = KaapavTheme.gold;
  static const Color goldLight = KaapavTheme.goldLight;
  static const Color goldDark = KaapavTheme.goldDark;
  static const Color white = KaapavTheme.white;
  static const Color cream = KaapavTheme.cream;
  static const Color dark = KaapavTheme.dark;
  static const Color darkSoft = KaapavTheme.darkSoft;
  static const Color gray = KaapavTheme.gray;
  static const Color grayLight = KaapavTheme.grayLight;
  static const Color border = KaapavTheme.border;
  static const Color success = KaapavTheme.success;
  static const Color error = KaapavTheme.error;
  static const Color warning = KaapavTheme.warning;
  static const Color info = KaapavTheme.info;
  static const Color purple = KaapavTheme.purple;
  static const Color sentBubble = KaapavTheme.sentBubble;
  static const Color receivedBubble = KaapavTheme.receivedBubble;
  static const Color readBlue = KaapavTheme.readBlue;
  static const LinearGradient goldGradient = KaapavTheme.goldGradient;
  static BoxShadow get goldShadow => KaapavTheme.goldShadow;
}