import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pottery-themed typography scale using pottery terminology
/// Creates a warm, artistic hierarchy suitable for ceramic arts documentation
class PotteryTypography {
  // --- Typography Scale: Pottery Terminology ---

  /// Kiln - Largest display text (like kiln size - big and important)
  static TextStyle get kiln => GoogleFonts.inter(
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Wheel - Large headings (like pottery wheel - central and prominent)
  static TextStyle get wheel => GoogleFonts.inter(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  /// Clay - Medium headings (like clay - the foundation material)
  static TextStyle get clay => GoogleFonts.inter(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Ceramic - Smaller headings (like ceramic - refined and polished)
  static TextStyle get ceramic => GoogleFonts.inter(
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  /// Glaze - Body text (like glaze - smooth and readable covering)
  static TextStyle get glaze => GoogleFonts.inter(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  /// Slip - Secondary text (like slip - thinner layer, supporting)
  static TextStyle get slip => GoogleFonts.inter(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  /// Tool - Small text (like pottery tool - precise and functional)
  static TextStyle get tool => GoogleFonts.inter(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // --- Semantic Typography Variants ---

  /// Emphasis variants for pottery stages
  static TextStyle kilnBold = kiln.copyWith(fontWeight: FontWeight.w800);
  static TextStyle wheelMedium = wheel.copyWith(fontWeight: FontWeight.w500);
  static TextStyle clayLight = clay.copyWith(fontWeight: FontWeight.w400);

  /// Stage-specific typography
  static TextStyle greenwareTitle = ceramic.copyWith(
    color: const Color(0xFF7BA05B), // PotteryColors.greenware
    fontWeight: FontWeight.w600,
  );

  static TextStyle bisqueTitle = ceramic.copyWith(
    color: const Color(0xFFB5A688), // PotteryColors.bisque
    fontWeight: FontWeight.w600,
  );

  static TextStyle finalTitle = ceramic.copyWith(
    color: const Color(0xFF6B7BA8), // PotteryColors.finalStage
    fontWeight: FontWeight.w600,
  );

  // --- Button Typography ---
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // --- Label Typography ---
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // --- Caption Typography ---
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    height: 1.6,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );

  // --- Material Typography Mapping ---
  /// Creates a Material TextTheme using pottery terminology
  static TextTheme createTextTheme({Color? textColor}) {
    final Color defaultColor = textColor ?? const Color(0xFF2C2A28);

    return GoogleFonts.interTextTheme().copyWith(
      // Display styles (Kiln level)
      displayLarge: kiln.copyWith(color: defaultColor),
      displayMedium: wheel.copyWith(color: defaultColor),
      displaySmall: clay.copyWith(color: defaultColor),

      // Headline styles (Wheel/Clay level)
      headlineLarge: wheel.copyWith(color: defaultColor),
      headlineMedium: clay.copyWith(color: defaultColor),
      headlineSmall: ceramic.copyWith(color: defaultColor),

      // Title styles (Ceramic level)
      titleLarge: ceramic.copyWith(color: defaultColor),
      titleMedium: GoogleFonts.inter(
        color: defaultColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.inter(
        color: defaultColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      // Body styles (Glaze level)
      bodyLarge: glaze.copyWith(color: defaultColor),
      bodyMedium: slip.copyWith(color: defaultColor),
      bodySmall: GoogleFonts.inter(
        color: defaultColor,
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),

      // Label styles (Tool level)
      labelLarge: labelLarge.copyWith(color: defaultColor),
      labelMedium: labelMedium.copyWith(color: defaultColor),
      labelSmall: labelSmall.copyWith(color: defaultColor),
    );
  }
}

/// Extension to provide pottery typography access on TextTheme
extension PotteryTextTheme on TextTheme {
  // Return themed versions with proper colors from the TextTheme
  TextStyle get kiln => displayLarge ?? PotteryTypography.kiln;
  TextStyle get wheel => displayMedium ?? PotteryTypography.wheel;
  TextStyle get clay => displaySmall ?? PotteryTypography.clay;
  TextStyle get ceramic => titleLarge ?? PotteryTypography.ceramic;
  TextStyle get glaze => bodyLarge ?? PotteryTypography.glaze;
  TextStyle get slip => bodyMedium ?? PotteryTypography.slip;
  TextStyle get tool => labelMedium ?? PotteryTypography.tool;

  // Stage-specific styles - use themed ceramic with stage colors
  TextStyle get greenwareTitle => ceramic.copyWith(
    color: const Color(0xFF7BA05B), // PotteryColors.greenware
    fontWeight: FontWeight.w600,
  );
  TextStyle get bisqueTitle => ceramic.copyWith(
    color: const Color(0xFFB5A688), // PotteryColors.bisque
    fontWeight: FontWeight.w600,
  );
  TextStyle get finalTitle => ceramic.copyWith(
    color: const Color(0xFF6B7BA8), // PotteryColors.finalStage
    fontWeight: FontWeight.w600,
  );

  // Button styles - keep these as static since they have specific requirements
  TextStyle get buttonLarge => PotteryTypography.buttonLarge;
  TextStyle get buttonMedium => PotteryTypography.buttonMedium;
  TextStyle get buttonSmall => PotteryTypography.buttonSmall;
}
