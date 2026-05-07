import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Base Screen Width for scaling calculations
  static const double baseWidth = 375.0;

  // Scaling logic based on screen width
  static double scale(BuildContext context, double size) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Cap the scaling for very large screens to avoid massive text
    double clampedWidth = screenWidth > 1200 ? 1200 : screenWidth;
    return size * (clampedWidth / baseWidth);
  }

  // Modern Font Family
  static String get fontFamily => GoogleFonts.outfit().fontFamily!;

  // Responsive Text Styles
  static TextStyle h1(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 32),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing ?? -0.5,
    );
  }

  static TextStyle h2(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 24),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing ?? -0.5,
    );
  }

  static TextStyle h3(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 20),
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle bodyLarge(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 18),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle bodyMedium(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 16),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle bodySmall(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 14),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.white70,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 12),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.white54,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle label(BuildContext context, {Color? color, FontWeight? fontWeight, double? letterSpacing, double? fontSize}) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? scale(context, 11),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing ?? 1.1,
    );
  }
}
