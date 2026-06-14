import 'package:flutter/material.dart';

// All Press Start 2P and Outfit usages go through these constants.
// Never call GoogleFonts.pressStart2p() or GoogleFonts.outfit() directly in widgets.

class AppTextStyles {
  AppTextStyles._();

  // ── Pixel font (Press Start 2P) ──────────────────────────────────────────

  static TextStyle pixel({
    required double size,
    Color color = Colors.white,
    List<Shadow>? shadows,
    double? height,
    double? letterSpacing,
    FontStyle fontStyle = FontStyle.normal,
    TextDecoration? decoration,
    Color? decorationColor,
  }) =>
      TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: size,
        color: color,
        shadows: shadows,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        decoration: decoration,
        decorationColor: decorationColor,
      );

  // Predefined semantic styles

  /// App title: "NAMMA BINGO" (home hero)
  static TextStyle get heroTitle => pixel(size: 20);

  /// Screen section headers
  static TextStyle get screenHeader => pixel(size: 12);

  /// Card / section sub-headers
  static TextStyle get subHeader => pixel(size: 9);

  /// Body-level pixel labels (buttons, nav labels, mission prefix)
  static TextStyle get label => pixel(size: 8);

  /// Tiny watermark labels (bingo column letters, field hints)
  static TextStyle get micro => pixel(size: 6);

  /// Very small annotation (e.g. #index tags)
  static TextStyle get nano => pixel(size: 7);

  // ── Outfit body font ────────────────────────────────────────────────────

  static TextStyle outfit({
    required double size,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    TextOverflow? overflow,
  }) =>
      TextStyle(
        fontFamily: 'Outfit',
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        overflow: overflow,
      );

  static TextStyle get body => outfit(size: 13, color: Colors.white70, height: 1.4);
  static TextStyle get bodySmall => outfit(size: 11, color: Colors.white60);
  static TextStyle get playerName => outfit(size: 14, weight: FontWeight.w700);
}
