import 'package:flutter/material.dart';

class AppColors {
  // === ARCADE CORE ===
  static const Color background     = Color(0xFF080810);
  static const Color surface        = Color(0xFF0F0F22);
  static const Color cardBackground = Color(0xFF14142E);

  // === NEON ACCENTS ===
  static const Color neonPink   = Color(0xFFFF006E);
  static const Color neonGreen  = Color(0xFF00FF87);
  static const Color neonBlue   = Color(0xFF00D4FF);
  static const Color neonYellow = Color(0xFFFFE600);
  static const Color neonPurple = Color(0xFFBF00FF);

  // === BACKWARDS-COMPAT ALIASES ===
  static const Color primaryBlue    = neonBlue;
  static const Color lightCyan      = neonBlue;
  static const Color navyDeep       = Color(0xFF0A0A1E);
  static const Color accentWhite    = Color(0xFFE0E0FF);
  static const Color dashYellow     = neonYellow;
  static const Color electricIndigo = neonPurple;
  static const Color neonMint       = neonGreen;
  static const Color vividAmber     = neonYellow;
  static const Color hotPink        = neonPink;
  static const Color success        = neonGreen;
  static const Color warning        = neonYellow;
  static const Color error          = Color(0xFFFF3A3A);

  static Color surfaceGlass =
      const Color(0xFFFFFFFF).withValues(alpha: 0.04);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonBlue, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0C0C1E), background, Color(0xFF060608)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white10, Colors.white24],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
