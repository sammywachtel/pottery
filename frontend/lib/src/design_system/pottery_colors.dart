import 'package:flutter/material.dart';

/// Pottery-themed color palette using OKLCH color space for vibrant, accessible colors
/// Inspired by ceramic earth tones and the pottery creation process
class PotteryColors {
  // --- Primary Colors: Ceramic Earth Tones ---

  /// Main brand color - warm ceramic brown
  static const clayPrimary = Color(0xFF8B6F47);        // oklch(55% 0.08 45)
  static const clayPrimaryLight = Color(0xFFB5967A);    // oklch(70% 0.06 45)
  static const clayPrimaryDark = Color(0xFF5D4A32);     // oklch(40% 0.10 45)

  // --- Stage Colors: Pottery Lifecycle ---

  /// Greenware stage - fresh clay ready for first firing
  static const greenware = Color(0xFF7BA05B);          // oklch(60% 0.12 140)
  static const greenwawreLight = Color(0xFFA4C285);     // oklch(75% 0.10 140)
  static const greenwareDark = Color(0xFF5B7A42);       // oklch(45% 0.14 140)

  /// Bisque stage - first firing complete, ready for glaze
  static const bisque = Color(0xFFB5A688);             // oklch(70% 0.08 65)
  static const bisqueLight = Color(0xFFCDC0A8);         // oklch(80% 0.06 65)
  static const bisqueDark = Color(0xFF9B8F73);          // oklch(60% 0.10 65)

  /// Final stage - glazed and completed pottery
  static const finalStage = Color(0xFF6B7BA8);         // oklch(55% 0.10 240)
  static const finalStageLight = Color(0xFF8EA2C7);     // oklch(70% 0.08 240)
  static const finalStageDark = Color(0xFF4A5A82);      // oklch(40% 0.12 240)

  // --- Neutral Palette: Clay & Ceramic Surfaces ---

  /// Primary surface - warm clay white
  static const surface = Color(0xFFFAF9F8);            // oklch(98% 0.005 45)
  static const surfaceVariant = Color(0xFFF0EFEC);      // oklch(92% 0.01 45)
  static const surfaceContainer = Color(0xFFF6F5F2);    // oklch(95% 0.008 45)
  static const surfaceDim = Color(0xFFE8E6E1);          // oklch(88% 0.015 45)

  /// Text and content colors
  static const onSurface = Color(0xFF1F1E1C);           // oklch(20% 0.02 45)
  static const onSurfaceVariant = Color(0xFF6B6862);    // oklch(45% 0.03 45)
  static const outline = Color(0xFF9C9A92);             // oklch(65% 0.02 45)
  static const outlineVariant = Color(0xFFCCC9C0);      // oklch(82% 0.015 45)

  // --- Semantic Colors ---

  /// Success - kiln fired successfully
  static const success = Color(0xFF5B8A3A);            // oklch(50% 0.12 130)
  static const successContainer = Color(0xFFD7F2B8);    // oklch(90% 0.08 130)
  static const onSuccess = Color(0xFFFFFFFF);
  static const onSuccessContainer = Color(0xFF162E06);

  /// Warning - needs attention
  static const warning = Color(0xFFB8882D);            // oklch(60% 0.12 70)
  static const warningContainer = Color(0xFFF7E6B8);    // oklch(90% 0.08 70)
  static const onWarning = Color(0xFFFFFFFF);
  static const onWarningContainer = Color(0xFF2D1F00);

  /// Error - firing failed
  static const error = Color(0xFFB8432D);              // oklch(50% 0.12 25)
  static const errorContainer = Color(0xFFF7D6D1);      // oklch(90% 0.08 25)
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF2D0F08);

  /// Info - pottery tips and guidance
  static const info = Color(0xFF2D7AB8);               // oklch(50% 0.12 225)
  static const infoContainer = Color(0xFFD1E6F7);       // oklch(90% 0.08 225)
  static const onInfo = Color(0xFFFFFFFF);
  static const onInfoContainer = Color(0xFF08192D);

  // --- Shadow Colors ---

  /// Clay shadow - warm subtle shadows
  static const clayShadow = Color(0x298B6F47);          // clayPrimary with 16% opacity

  /// Ceramic shadow - deeper shadows for elevated elements
  static const ceramicShadow = Color(0x268B6F47);       // clayPrimary with 15% opacity

  // --- Stage Color Utilities ---

  /// Get the appropriate color for a pottery stage
  static Color getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'greenware':
        return greenware;
      case 'bisque':
        return bisque;
      case 'final':
        return finalStage;
      default:
        return clayPrimary;
    }
  }

  /// Get the light variant of a stage color
  static Color getStageColorLight(String stage) {
    switch (stage.toLowerCase()) {
      case 'greenware':
        return greenwawreLight;
      case 'bisque':
        return bisqueLight;
      case 'final':
        return finalStageLight;
      default:
        return clayPrimaryLight;
    }
  }

  /// Get the dark variant of a stage color
  static Color getStageColorDark(String stage) {
    switch (stage.toLowerCase()) {
      case 'greenware':
        return greenwareDark;
      case 'bisque':
        return bisqueDark;
      case 'final':
        return finalStageDark;
      default:
        return clayPrimaryDark;
    }
  }
}

/// Extension to provide semantic color access on ThemeData
extension PotteryThemeColors on ThemeData {
  Color get clayPrimary => PotteryColors.clayPrimary;
  Color get greenware => PotteryColors.greenware;
  Color get bisque => PotteryColors.bisque;
  Color get finalStage => PotteryColors.finalStage;
  Color get clayShadow => PotteryColors.clayShadow;
}
