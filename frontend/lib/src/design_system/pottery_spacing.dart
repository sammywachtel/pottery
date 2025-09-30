import 'package:flutter/material.dart';

/// Pottery-themed spacing system using clay grid methodology
/// Based on 4px base unit (like clay thickness) for consistent visual rhythm
class PotterySpacing {
  /// Base unit - like clay thickness (4px)
  static const double baseUnit = 4.0;

  // --- Spacing Scale: Clay Grid System ---

  /// Slip - Thinnest layer (4px)
  static const double slip = baseUnit * 1; // 4px

  /// Tool - Tool precision (8px)
  static const double tool = baseUnit * 2; // 8px

  /// Trim - Trimming margin (12px)
  static const double trim = baseUnit * 3; // 12px

  /// Clay - Standard clay thickness (16px)
  static const double clay = baseUnit * 4; // 16px

  /// Throw - Throwing distance (20px)
  static const double throwing = baseUnit * 5; // 20px

  /// Center - Centering space (24px)
  static const double center = baseUnit * 6; // 24px

  /// Wheel - Pottery wheel diameter (32px)
  static const double wheel = baseUnit * 8; // 32px

  /// Fire - Firing chamber (40px)
  static const double fire = baseUnit * 10; // 40px

  /// Kiln - Large kiln space (48px)
  static const double kiln = baseUnit * 12; // 48px

  /// Studio - Full studio width (64px)
  static const double studio = baseUnit * 16; // 64px

  // --- Semantic Spacing ---

  /// Component internal spacing
  static const double componentPadding = clay; // 16px
  static const double componentMargin = center; // 24px

  /// Touch target spacing
  static const double touchTarget = 44.0; // Minimum touch target
  static const double touchPadding = clay; // 16px around touch targets

  /// Card spacing
  static const double cardPadding = clay; // 16px
  static const double cardMargin = trim; // 12px
  static const double cardSpacing = center; // 24px between cards

  /// List spacing
  static const double listItemPadding = clay; // 16px
  static const double listItemSpacing = tool; // 8px
  static const double listSectionSpacing = wheel; // 32px

  /// Form spacing
  static const double fieldSpacing = clay; // 16px between form fields
  static const double sectionSpacing = wheel; // 32px between form sections
  static const double formPadding = center; // 24px form container padding

  /// Screen spacing
  static const double screenPadding = clay; // 16px screen edges
  static const double screenMargin = center; // 24px between screen sections

  /// Photo spacing (important for pottery visual documentation)
  static const double photoSpacing = trim; // 12px between photos
  static const double photoMargin = clay; // 16px around photo containers
  static const double gallerySpacing = tool; // 8px in tight photo grids

  // --- Responsive Spacing Utilities ---

  /// Get responsive padding based on screen width
  static double getResponsivePadding(double screenWidth) {
    if (screenWidth > 768) return center; // Tablet/desktop
    if (screenWidth > 480) return clay; // Large phone
    return trim; // Small phone
  }

  /// Get responsive margin based on screen width
  static double getResponsiveMargin(double screenWidth) {
    if (screenWidth > 768) return wheel; // Tablet/desktop
    if (screenWidth > 480) return center; // Large phone
    return clay; // Small phone
  }

  // --- Animation & Transition Spacing ---

  /// Micro-interaction distances
  static const double bounceDistance = tool; // 8px clay bounce
  static const double rippleRadius = throwing; // 20px touch ripple
  static const double slideDistance = wheel; // 32px slide transitions

  // --- Border Radius: Pottery Edges ---

  /// Sharp edge - fresh cut clay
  static const double sharp = 0.0;

  /// Soft edge - slightly rounded like hand-formed clay
  static const double soft = baseUnit * 1.5; // 6px

  /// Round edge - pottery curves
  static const double round = tool; // 8px

  /// Smooth edge - well-thrown pottery
  static const double smooth = trim; // 12px

  /// Ceramic edge - finished pottery roundness
  static const double ceramic = clay; // 16px

  /// Perfect circle - like pottery wheel
  static const double circle = 999.0;

  // --- Shadow & Elevation Spacing ---

  /// Clay shadow offset
  static const double clayShadowOffset = slip; // 4px

  /// Ceramic shadow offset
  static const double ceramicShadowOffset = tool; // 8px

  /// Kiln shadow blur
  static const double kilnShadowBlur = trim; // 12px
}

/// Extension to provide pottery spacing access on commonly used widgets
extension PotterySpacingExtension on double {
  /// Convert number to SizedBox with pottery spacing
  Widget get verticalSpace => SizedBox(height: this);
  Widget get horizontalSpace => SizedBox(width: this);
}

/// Common spacing widgets for pottery app
class PotterySpace {
  // Vertical spacing widgets
  static const Widget slipVertical = SizedBox(height: PotterySpacing.slip);
  static const Widget toolVertical = SizedBox(height: PotterySpacing.tool);
  static const Widget trimVertical = SizedBox(height: PotterySpacing.trim);
  static const Widget clayVertical = SizedBox(height: PotterySpacing.clay);
  static const Widget throwingVertical = SizedBox(height: PotterySpacing.throwing);
  static const Widget centerVertical = SizedBox(height: PotterySpacing.center);
  static const Widget wheelVertical = SizedBox(height: PotterySpacing.wheel);

  // Horizontal spacing widgets
  static const Widget slipHorizontal = SizedBox(width: PotterySpacing.slip);
  static const Widget toolHorizontal = SizedBox(width: PotterySpacing.tool);
  static const Widget trimHorizontal = SizedBox(width: PotterySpacing.trim);
  static const Widget clayHorizontal = SizedBox(width: PotterySpacing.clay);
  static const Widget throwingHorizontal = SizedBox(width: PotterySpacing.throwing);
  static const Widget centerHorizontal = SizedBox(width: PotterySpacing.center);
  static const Widget wheelHorizontal = SizedBox(width: PotterySpacing.wheel);
}
