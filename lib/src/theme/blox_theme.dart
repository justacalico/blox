import 'package:flutter/material.dart';

/// Design tokens for Blox.
///
/// The look: a deep indigo playfield, a dark recessed board, and glossy
/// candy blocks with a hard top light and a soft bottom shadow.
abstract final class BloxColors {
  // Backdrop
  static const Color backdropTop = Color(0xFF3D4472);
  static const Color backdropBottom = Color(0xFF2A2E51);

  // Board
  static const Color boardWell = Color(0xFF1F2342);
  static const Color boardEdge = Color(0xFF181B34);
  static const Color cell = Color(0xFF272C50);
  static const Color cellAlt = Color(0xFF252A4B);
  static const Color cellHover = Color(0xFF343B68);
  static const Color cellGhost = Color(0xFF3A4270);

  // Blocks
  static const Color green = Color(0xFF45D354);
  static const Color red = Color(0xFFE8524B);
  static const Color orange = Color(0xFFF08A30);
  static const Color yellow = Color(0xFFF2C437);
  static const Color blue = Color(0xFF3F7FE4);
  static const Color cyan = Color(0xFF3CC6DC);
  static const Color purple = Color(0xFF9B5CD6);

  static const List<Color> blocks = <Color>[
    green,
    red,
    orange,
    yellow,
    blue,
    cyan,
    purple,
  ];

  // UI
  static const Color ink = Color(0xFFFFFFFF);
  static const Color inkSoft = Color(0xFFB9C0E8);
  static const Color crown = Color(0xFFF7BC3F);
  static const Color ctaOrange = Color(0xFFF5A62B);
  static const Color ctaOrangeDeep = Color(0xFFD98A1B);
  static const Color ctaTeal = Color(0xFF2FBF9B);
  static const Color ctaTealDeep = Color(0xFF22A083);
  static const Color ctaBlue = Color(0xFF35A5E8);
  static const Color ctaBlueDeep = Color(0xFF2A8AC8);
  static const Color panel = Color(0xFF333B6B);
  static const Color panelDeep = Color(0xFF282F58);
  static const Color glow = Color(0xFF9FFFC9);
  static const Color danger = Color(0xFFFF6B6B);
}

abstract final class BloxMetrics {
  static const int boardSize = 8;
  static const double boardPadding = 10;
  static const double boardRadius = 14;
  static const double cellGap = 2.5;
  static const double cellRadius = 4;
  static const double blockRadiusFactor = 0.22;
  static const double traySlot = 96;
}

abstract final class BloxMotion {
  static const Duration snap = Duration(milliseconds: 120);
  static const Duration pop = Duration(milliseconds: 180);
  static const Duration clear = Duration(milliseconds: 320);
  static const Duration float = Duration(milliseconds: 700);
  static const Curve snapCurve = Curves.easeOutCubic;
  static const Curve popCurve = Curves.easeOutBack;
}

abstract final class BloxText {
  static const String family = 'Fredoka';

  static TextStyle display(double size, {Color color = BloxColors.ink}) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1,
      letterSpacing: 0.5,
    );
  }

  static TextStyle label(double size, {Color color = BloxColors.inkSoft}) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color,
      letterSpacing: 0.4,
    );
  }
}

abstract final class BloxTheme {
  static ThemeData material() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: BloxText.family,
      scaffoldBackgroundColor: BloxColors.backdropBottom,
      colorScheme: const ColorScheme.dark(
        primary: BloxColors.ctaOrange,
        surface: BloxColors.panel,
        onSurface: BloxColors.ink,
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
