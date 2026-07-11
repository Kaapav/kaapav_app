import 'package:flutter/material.dart';

class KaapavTheme {
  KaapavTheme._();

  // ═══════════════════════════════════════════
  // KAAPAV AURORA LUXE GLASS — CORE COLORS
  // ═══════════════════════════════════════════
  static const Color gold = Color(0xFFC49432);
  static const Color goldLight = Color(0xFFD4A84B);
  static const Color goldDark = Color(0xFFA67C28);
  static const Color champagne = Color(0xFFFFE3A3);

  static const Color bgDeep = Color(0xFF050403);
  static const Color bg = Color(0xFF0B0804);
  static const Color bgCard = Color(0xFF15110A);
  static const Color bgLight = Color(0xFF21190E);

  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFBF8F1);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color darkSoft = Color(0xFF374151);
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);

  // Glass
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);
  static const Color glassGold = Color(0x22C49432);
  static const Color glassGoldBorder = Color(0x55C49432);

  // Colourful semantic accents
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color rose = Color(0xFFEC4899);
  static const Color teal = Color(0xFF14B8A6);
  static const Color sapphire = Color(0xFF3B82F6);
  static const Color emerald = Color(0xFF10B981);
  static const Color ruby = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amethyst = Color(0xFF8B5CF6);

  // Message bubbles
  static const Color sentBubble = gold;
  static const Color receivedBubble = white;
  static const Color darkSentBubble = goldDark;
  static const Color darkReceivedBubble = Color(0xFF201A12);
  static const Color readBlue = Color(0xFF53BDEB);

  // Labels
  static const Color vipLabel = Color(0xFFFFD700);
  static const Color hotLeadLabel = rose;
  static const Color newLabel = teal;
  static const Color returningLabel = sapphire;
  static const Color wholesaleLabel = emerald;

  // ═══════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxeGoldGradient = LinearGradient(
    colors: [champagne, goldLight, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [bgDeep, bg, bgCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSentBubbleGradient = LinearGradient(
    colors: [goldLight, gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [emerald, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [amber, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [ruby, rose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [sapphire, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> auroraColors = [
    gold,
    amethyst,
    teal,
    rose,
    sapphire,
    emerald,
    amber,
  ];

  static BoxShadow get goldShadow => BoxShadow(
        color: gold.withValues(alpha: 0.30),
        blurRadius: 18,
        spreadRadius: 1,
        offset: const Offset(0, 8),
      );

  static BoxShadow glow(Color color, {double opacity = 0.28}) => BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 26,
        spreadRadius: 2,
        offset: const Offset(0, 10),
      );

  // ═══════════════════════════════════════════
  // MAIN THEME GETTERS
  // ═══════════════════════════════════════════
  static ThemeData get lightTheme => _lightTheme();
  static ThemeData get darkTheme => _darkTheme();

  // ═══════════════════════════════════════════
  // STATUS HELPERS
  // ═══════════════════════════════════════════
  static Color orderStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return amber.withValues(alpha: 0.16);
      case 'confirmed':
        return sapphire.withValues(alpha: 0.16);
      case 'processing':
        return amethyst.withValues(alpha: 0.16);
      case 'shipped':
        return teal.withValues(alpha: 0.16);
      case 'delivered':
        return emerald.withValues(alpha: 0.16);
      case 'cancelled':
      case 'returned':
        return ruby.withValues(alpha: 0.16);
      default:
        return glassWhite;
    }
  }

  static Color orderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return amber;
      case 'confirmed':
        return sapphire;
      case 'processing':
        return amethyst;
      case 'shipped':
        return teal;
      case 'delivered':
        return emerald;
      case 'cancelled':
      case 'returned':
        return ruby;
      default:
        return grayLight;
    }
  }

  static IconData orderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'processing':
        return Icons.settings_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.inventory_2_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'returned':
        return Icons.assignment_return_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static Color paymentStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'unpaid':
        return ruby.withValues(alpha: 0.16);
      case 'paid':
        return emerald.withValues(alpha: 0.16);
      case 'refunded':
        return amethyst.withValues(alpha: 0.16);
      default:
        return glassWhite;
    }
  }

  static Color paymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'unpaid':
        return ruby;
      case 'paid':
        return emerald;
      case 'refunded':
        return amethyst;
      default:
        return grayLight;
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

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'bracelets':
        return gold;
      case 'necklaces':
        return amethyst;
      case 'rings':
        return rose;
      case 'earrings':
        return sapphire;
      case 'sets':
        return emerald;
      case 'pendants':
        return teal;
      default:
        return gold;
    }
  }

  // ═══════════════════════════════════════════
  // LIGHT THEME — kept usable, but premium
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
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: gold,
        unselectedItemColor: grayLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: white,
        textColor: dark,
        borderColor: border,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: gold),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: white,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: cream,
        selectedColor: gold.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark,
        contentTextStyle: const TextStyle(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  // DARK THEME — KAAPAV AURORA LUXE GLASS
  // ═══════════════════════════════════════════
  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: bgCard,
        error: error,
      ),
      scaffoldBackgroundColor: bgDeep,
      canvasColor: bgDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg.withValues(alpha: 0.92),
        selectedItemColor: goldLight,
        unselectedItemColor: grayLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: glassBorder),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: Colors.white.withValues(alpha: 0.07),
        textColor: white,
        borderColor: glassBorder,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: bgDeep,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: goldLight),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldLight,
          side: BorderSide(color: gold.withValues(alpha: 0.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: bgDeep,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: glassBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: glassWhite,
        selectedColor: gold.withValues(alpha: 0.18),
        labelStyle: const TextStyle(fontSize: 13, color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: glassBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: const TextStyle(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: goldLight,
        unselectedLabelColor: grayLight,
        indicatorColor: gold,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color textColor,
    required Color borderColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(color: grayLight.withValues(alpha: 0.82)),
      labelStyle: TextStyle(color: grayLight.withValues(alpha: 0.95)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: goldLight, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// Alias — existing files using KaapavColors will still work.
class KaapavColors {
  KaapavColors._();

  static const Color gold = KaapavTheme.gold;
  static const Color goldLight = KaapavTheme.goldLight;
  static const Color goldDark = KaapavTheme.goldDark;
  static const Color champagne = KaapavTheme.champagne;

  static const Color bgDeep = KaapavTheme.bgDeep;
  static const Color bg = KaapavTheme.bg;
  static const Color bgCard = KaapavTheme.bgCard;
  static const Color bgLight = KaapavTheme.bgLight;

  static const Color white = KaapavTheme.white;
  static const Color cream = KaapavTheme.cream;
  static const Color dark = KaapavTheme.dark;
  static const Color darkSoft = KaapavTheme.darkSoft;
  static const Color gray = KaapavTheme.gray;
  static const Color grayLight = KaapavTheme.grayLight;
  static const Color border = KaapavTheme.border;

  static const Color glassWhite = KaapavTheme.glassWhite;
  static const Color glassBorder = KaapavTheme.glassBorder;
  static const Color glassGold = KaapavTheme.glassGold;
  static const Color glassGoldBorder = KaapavTheme.glassGoldBorder;

  static const Color success = KaapavTheme.success;
  static const Color error = KaapavTheme.error;
  static const Color warning = KaapavTheme.warning;
  static const Color info = KaapavTheme.info;
  static const Color purple = KaapavTheme.purple;
  static const Color rose = KaapavTheme.rose;
  static const Color teal = KaapavTheme.teal;
  static const Color sapphire = KaapavTheme.sapphire;
  static const Color emerald = KaapavTheme.emerald;
  static const Color ruby = KaapavTheme.ruby;
  static const Color amber = KaapavTheme.amber;
  static const Color amethyst = KaapavTheme.amethyst;

  static const Color sentBubble = KaapavTheme.sentBubble;
  static const Color receivedBubble = KaapavTheme.receivedBubble;
  static const Color darkSentBubble = KaapavTheme.darkSentBubble;
  static const Color darkReceivedBubble = KaapavTheme.darkReceivedBubble;
  static const Color readBlue = KaapavTheme.readBlue;

  static const LinearGradient goldGradient = KaapavTheme.goldGradient;
  static const LinearGradient luxeGoldGradient = KaapavTheme.luxeGoldGradient;
  static const LinearGradient darkBgGradient = KaapavTheme.darkBgGradient;
  static const LinearGradient darkSentBubbleGradient =
      KaapavTheme.darkSentBubbleGradient;

  static BoxShadow get goldShadow => KaapavTheme.goldShadow;
}