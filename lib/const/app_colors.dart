import 'package:flutter/material.dart';

class AppColors {
  // Dash Theme Palette (Base Foundation)
  static const Color primaryBlue = Color(0xFF027DFD);
  static const Color lightCyan = Color(0xFF40D0FB);
  static const Color navyDeep = Color(0xFF042B59);
  static const Color accentWhite = Color(0xFFFFFFFF);
  static const Color dashYellow = Color(0xFFFFF176);
  
  // Vibrant Accents (New additions for depth and energy)
  static const Color electricIndigo = Color(0xFF6366F1);
  static const Color neonMint = Color(0xFF10B981);
  static const Color vividAmber = Color(0xFFF59E0B);
  static const Color hotPink = Color(0xFFEC4899);
  
  // Neutral / Utility
  static const Color background = Color(0xFF021B3A); // Darker, more premium navy
  static const Color cardBackground = Color(0xFF0A3669); 
  static const Color surface = Color(0xFF15437A); 
  static Color surfaceGlass = const Color(0xFFFFFFFF).withOpacity(0.05);
  
  // Sophisticated Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, lightCyan, electricIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [hotPink, vividAmber],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF042B59), Color(0xFF021B3A), Color(0xFF010D1E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white10, Colors.white24],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
