import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pottery_colors.dart';
import 'pottery_typography.dart';
import 'pottery_spacing.dart';

/// Complete pottery-themed Material Design system
/// Transforms the Flutter app with warm, ceramic-inspired aesthetics
class PotteryTheme {
  /// Creates the light pottery theme
  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      // Primary colors - ceramic earth tones
      primary: PotteryColors.clayPrimary,
      onPrimary: Colors.white,
      primaryContainer: PotteryColors.clayPrimaryLight,
      onPrimaryContainer: PotteryColors.clayPrimaryDark,

      // Secondary colors - pottery stages
      secondary: PotteryColors.greenware,
      onSecondary: Colors.white,
      secondaryContainer: PotteryColors.greenwawreLight,
      onSecondaryContainer: PotteryColors.greenwareDark,

      tertiary: PotteryColors.finalStage,
      onTertiary: PotteryColors.finalStageDark,
      tertiaryContainer: PotteryColors.finalStageLight,
      onTertiaryContainer: PotteryColors.finalStageDark,

      // Surface colors - clay and ceramic surfaces
      surface: PotteryColors.surface,
      onSurface: PotteryColors.onSurface,
      surfaceVariant: PotteryColors.surfaceVariant,
      onSurfaceVariant: PotteryColors.onSurfaceVariant,
      surfaceContainerHighest: PotteryColors.surfaceContainer,
      surfaceContainerHigh: PotteryColors.surfaceVariant,
      surfaceContainer: PotteryColors.surfaceContainer,
      surfaceContainerLow: PotteryColors.surface,
      surfaceContainerLowest: PotteryColors.surface,
      surfaceDim: PotteryColors.surfaceDim,
      surfaceBright: PotteryColors.surface,

      // Semantic colors
      error: PotteryColors.error,
      onError: PotteryColors.onError,
      errorContainer: PotteryColors.errorContainer,
      onErrorContainer: PotteryColors.onErrorContainer,

      // Outlines and borders
      outline: PotteryColors.outline,
      outlineVariant: PotteryColors.outlineVariant,

      // Shadows
      shadow: PotteryColors.clayShadow,
      scrim: Colors.black54,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: PotteryTypography.createTextTheme(
        textColor: colorScheme.onSurface,
      ),

      // App Bar Theme - pottery studio header
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: PotteryColors.clayShadow,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: PotteryTypography.clay.copyWith(
          color: colorScheme.onSurface,
        ),
        toolbarTextStyle: PotteryTypography.glaze.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 24,
        ),
      ),

      // Card Theme - pottery item cards
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shadowColor: PotteryColors.clayShadow,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.smooth),
        ),
        margin: const EdgeInsets.all(PotterySpacing.cardMargin),
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button Theme - pottery actions
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shadowColor: PotteryColors.clayShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PotterySpacing.round),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PotterySpacing.clay,
            vertical: PotterySpacing.trim,
          ),
          minimumSize: const Size(
            PotterySpacing.touchTarget * 2,
            PotterySpacing.touchTarget,
          ),
          textStyle: PotteryTypography.buttonMedium,
        ),
      ),

      // Filled Button Theme - primary pottery actions
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PotterySpacing.round),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PotterySpacing.clay,
            vertical: PotterySpacing.trim,
          ),
          minimumSize: const Size(
            PotterySpacing.touchTarget * 2,
            PotterySpacing.touchTarget,
          ),
          textStyle: PotteryTypography.buttonMedium,
        ),
      ),

      // Text Button Theme - subtle pottery actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PotterySpacing.round),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PotterySpacing.clay,
            vertical: PotterySpacing.trim,
          ),
          minimumSize: const Size(
            PotterySpacing.touchTarget,
            PotterySpacing.touchTarget,
          ),
          textStyle: PotteryTypography.buttonMedium,
        ),
      ),

      // Floating Action Button Theme - quick pottery actions
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.ceramic),
        ),
      ),

      // Input Decoration Theme - pottery forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PotterySpacing.clay,
          vertical: PotterySpacing.trim,
        ),
        labelStyle: PotteryTypography.slip,
        hintStyle: PotteryTypography.slip.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Chip Theme - pottery tags and filters
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        shadowColor: PotteryColors.clayShadow,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        pressElevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: PotterySpacing.trim,
          vertical: PotterySpacing.tool,
        ),
        labelPadding: const EdgeInsets.symmetric(
          horizontal: PotterySpacing.tool,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.ceramic),
        ),
        labelStyle: PotteryTypography.labelMedium,
        secondaryLabelStyle: PotteryTypography.labelMedium,
        brightness: Brightness.light,
      ),

      // List Tile Theme - pottery item lists
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PotterySpacing.clay,
          vertical: PotterySpacing.tool,
        ),
        minVerticalPadding: PotterySpacing.tool,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.12),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: PotteryTypography.glaze,
        subtitleTextStyle: PotteryTypography.slip,
        leadingAndTrailingTextStyle: PotteryTypography.slip,
      ),

      // Bottom Navigation Theme - pottery app navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
        selectedLabelStyle: PotteryTypography.labelSmall,
        unselectedLabelStyle: PotteryTypography.labelSmall,
        elevation: 8,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: PotteryColors.clayShadow,
        height: 72,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return PotteryTypography.labelSmall.copyWith(
              color: colorScheme.onSurface,
            );
          }
          return PotteryTypography.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // Tab Bar Theme - pottery stage navigation
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: PotteryTypography.labelLarge,
        unselectedLabelStyle: PotteryTypography.labelLarge,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 3,
          ),
          insets: const EdgeInsets.symmetric(
            horizontal: PotterySpacing.clay,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colorScheme.outlineVariant,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceVariant,
        circularTrackColor: colorScheme.surfaceVariant,
      ),

      // Snack Bar Theme - pottery notifications
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: PotteryTypography.glaze.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Dialog Theme - pottery dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: PotteryColors.ceramicShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.smooth),
        ),
        titleTextStyle: PotteryTypography.clay.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: PotteryTypography.glaze.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // Visual Density - comfortable for pottery workflow
      visualDensity: VisualDensity.comfortable,

      // Material Tap Target Size - pottery-friendly
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // Page Transitions - smooth pottery workflow
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Creates the dark pottery theme
  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
      // Primary colors - ceramic earth tones (adjusted for dark)
      primary: PotteryColors.clayPrimaryLight,
      onPrimary: PotteryColors.clayPrimaryDark,
      primaryContainer: PotteryColors.clayPrimaryDark,
      onPrimaryContainer: PotteryColors.clayPrimaryLight,

      // Secondary colors - pottery stages (adjusted for dark)
      secondary: PotteryColors.greenwawreLight,
      onSecondary: PotteryColors.greenwareDark,
      secondaryContainer: PotteryColors.greenwareDark,
      onSecondaryContainer: PotteryColors.greenwawreLight,

      tertiary: PotteryColors.finalStageLight,
      onTertiary: PotteryColors.finalStageDark,
      tertiaryContainer: PotteryColors.finalStageDark,
      onTertiaryContainer: PotteryColors.finalStageLight,

      // Surface colors - dark pottery surfaces
      surface: Color(0xFF1A1918), // Dark clay
      onSurface: Color(0xFFE8E6E1), // Light ceramic
      surfaceVariant: Color(0xFF2A2926), // Dark surface variant
      onSurfaceVariant: Color(0xFFCAC7BE), // Light on surface variant
      surfaceContainerHighest: Color(0xFF342F2E),
      surfaceContainerHigh: Color(0xFF2F2B2A),
      surfaceContainer: Color(0xFF252220),
      surfaceContainerLow: Color(0xFF201D1C),
      surfaceContainerLowest: Color(0xFF1A1918),
      surfaceDim: Color(0xFF141211),
      surfaceBright: Color(0xFF413E3C),

      // Semantic colors (adjusted for dark)
      error: PotteryColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFF601410),
      onErrorContainer: Color(0xFFF2B8B5),

      // Outlines and borders (adjusted for dark)
      outline: Color(0xFF54524E),
      outlineVariant: Color(0xFF2F2B2A),

      // Shadows (darker)
      shadow: Colors.black,
      scrim: Colors.black87,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: PotteryTypography.createTextTheme(
        textColor: colorScheme.onSurface,
      ),

      // App Bar Theme - pottery studio header (dark)
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: PotteryTypography.clay.copyWith(
          color: colorScheme.onSurface,
        ),
        toolbarTextStyle: PotteryTypography.glaze.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 24,
        ),
      ),

      // Card Theme - pottery item cards (dark)
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
        ),
      ),

      // Input Decoration Theme - pottery forms (dark)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
      ),

      // Floating Action Button Theme (dark)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.ceramic),
        ),
      ),
    );
  }
}

/// Pottery theme extensions for accessing pottery-specific styling
extension PotteryThemeExtension on ThemeData {
  /// Get stage-specific color
  Color getStageColor(String stage) {
    return PotteryColors.getStageColor(stage);
  }

  /// Get pottery spacing values
  double get claySpacing => PotterySpacing.clay;
  double get trimSpacing => PotterySpacing.trim;
  double get wheelSpacing => PotterySpacing.wheel;
  double get touchTargetSize => PotterySpacing.touchTarget;

  /// Get pottery typography
  TextStyle get kilnStyle => textTheme.kiln;
  TextStyle get wheelStyle => textTheme.wheel;
  TextStyle get clayStyle => textTheme.clay;
  TextStyle get ceramicStyle => textTheme.ceramic;
  TextStyle get glazeStyle => textTheme.glaze;
  TextStyle get slipStyle => textTheme.slip;
  TextStyle get toolStyle => textTheme.tool;
}
