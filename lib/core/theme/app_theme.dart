import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/theme/app_typography.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = AppPalette.emeraldCore;
    final surface = isDark ? AppPalette.navyElevated : Colors.white;
    final onSurface =
        isDark ? AppPalette.textPrimaryDark : AppPalette.textPrimaryLight;
    final textTheme = AppTypography.themeTextTheme(isDark: isDark);
    final typeExt = AppTypographyExtension.forBrightness(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? AppPalette.navyVoid : AppPalette.frost,
      fontFamily: AppTypography.uiFontFamily,
      fontFamilyFallback: const [
        'Inter',
        'SF Pro Display',
        'Segoe UI',
        'Roboto',
        'sans-serif',
      ],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: AppPalette.textPrimaryDark,
        secondary: AppPalette.neonMint,
        onSecondary: AppPalette.ink,
        surface: surface,
        onSurface: onSurface,
        error: AppPalette.crimson,
        onError: AppPalette.textPrimaryDark,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [typeExt],
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      dividerColor: isDark
          ? AppPalette.slateBorder
          : AppPalette.mist.withValues(alpha: 0.8),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        toolbarTextStyle: textTheme.bodyMedium,
        iconTheme: IconThemeData(color: onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppPalette.navySurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark
              ? AppPalette.textSecondaryDark
              : AppPalette.textSecondaryLight,
        ),
        labelStyle: textTheme.labelMedium,
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppPalette.emeraldBright,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(
            color: isDark ? AppPalette.slateBorder : AppPalette.mist,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(
            color: isDark ? AppPalette.slateBorder : AppPalette.mist,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppPalette.emeraldBright, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: typeExt.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: typeExt.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: typeExt.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        leadingAndTrailingTextStyle: textTheme.labelMedium,
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppPalette.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
        backgroundColor: isDark ? AppPalette.navySurface : AppPalette.ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppPalette.navyDeep : Colors.white,
        indicatorColor: AppPalette.emeraldCore.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelSmall!;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: AppPalette.emeraldBright,
              fontWeight: FontWeight.w600,
            );
          }
          return base;
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        extendedTextStyle: typeExt.button,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.emeraldBright,
        linearTrackColor: AppPalette.graphite,
      ),
      popupMenuTheme: PopupMenuThemeData(
        textStyle: textTheme.bodyMedium,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      bannerTheme: MaterialBannerThemeData(
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}
