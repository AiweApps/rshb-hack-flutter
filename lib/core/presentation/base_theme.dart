import 'package:flutter/material.dart';

import '../constants/app_colors_constants.dart';
import '../constants/app_style_constants.dart';
import '../constants/app_text_styles_constants.dart';

/// Builds the app theme for a brightness.
///
/// Design tokens — [AppColors] and [AppTextStyles] — are the source of truth.
/// Everything Material needs ([ColorScheme], [TextTheme], component themes) is
/// *derived* from them here, so the two can never drift apart. Application code
/// reads the tokens (`context.colors`, `context.ts`) and never `ColorScheme` or
/// `TextTheme`.
ThemeData getBaseTheme({Brightness brightness = Brightness.light}) {
  final AppColors colors = brightness == Brightness.light
      ? AppColors.light
      : AppColors.dark;
  final AppTextStyles textStyles = AppTextStyles.from(colors);
  final ColorScheme colorScheme = _colorSchemeFrom(colors, brightness);
  const RoundedRectangleBorder pill = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.rPill)),
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: _textThemeFrom(textStyles),
    scaffoldBackgroundColor: colors.paper,
    canvasColor: colors.paper,
    splashColor: colors.wine.withAlpha(AppAlpha.a12),
    highlightColor: colors.wine.withAlpha(AppAlpha.a8),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: colors.paper,
      foregroundColor: colors.ink,
      titleTextStyle: textStyles.appBarTitle,
      iconTheme: IconThemeData(color: colors.ink, size: AppSize.s24),
    ),
    dividerTheme: DividerThemeData(
      thickness: AppSize.dividerThickness,
      space: AppSize.dividerThickness,
      color: colors.rule,
    ),
    listTileTheme: ListTileThemeData(
      textColor: colors.ink,
      titleTextStyle: textStyles.paragraph,
      subtitleTextStyle: textStyles.paragraphTiny,
      iconColor: colors.ink2,
      tileColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: colors.card,
      dragHandleColor: colors.rule,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r24),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textStyles.h3,
      contentTextStyle: textStyles.paragraph,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r20)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.wine,
      strokeWidth: AppSize.s2,
    ),
    // Primary pill: wine fill.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll<Color>(colors.onWine),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.wine.withAlpha(AppAlpha.a40)
              : colors.wine,
        ),
        overlayColor: WidgetStatePropertyAll<Color>(
          colors.onWine.withAlpha(AppAlpha.a12),
        ),
        elevation: const WidgetStatePropertyAll<double>(0),
        textStyle: WidgetStatePropertyAll<TextStyle?>(textStyles.button),
        minimumSize: const WidgetStatePropertyAll<Size?>(
          Size(AppSize.s0, AppSize.buttonHeight),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(
            horizontal: AppPadding.p24,
            vertical: AppPadding.p12,
          ),
        ),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(pill),
      ),
    ),
    // Ghost pill: wine outline.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(colors.wine),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: WidgetStatePropertyAll<Color>(
          colors.wine.withAlpha(AppAlpha.a12),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle?>(textStyles.button),
        minimumSize: const WidgetStatePropertyAll<Size?>(
          Size(AppSize.s0, AppSize.buttonHeight),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(
            horizontal: AppPadding.p20,
            vertical: AppPadding.p12,
          ),
        ),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: colors.wine, width: AppSize.s1_5),
        ),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(pill),
      ),
    ),
    // Text-only action, e.g. a link in a card.
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(AppSize.s0, AppSize.minTapTarget),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(colors.wine),
        overlayColor: WidgetStatePropertyAll<Color>(
          colors.wine.withAlpha(AppAlpha.a12),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle?>(textStyles.buttonSmall),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(pill),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll<Color>(colors.ink),
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(AppSize.minTapTarget, AppSize.minTapTarget),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? colors.onWine : colors.card,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? colors.wine : colors.rule,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(colors.wine)),
    chipTheme: ChipThemeData(
      backgroundColor: colors.paper2,
      selectedColor: colors.wine,
      labelStyle: textStyles.tab,
      side: BorderSide(color: colors.rule),
      shape: pill,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.ink,
      contentTextStyle: textStyles.paragraphSmall.copyWith(color: colors.paper),
    ),
    extensions: <ThemeExtension<dynamic>>[colors, textStyles],
  );
}

/// Maps design tokens onto Material's fixed colour slots.
///
/// This exists only so stock Material widgets (dialogs, text fields, ripples)
/// pick up the palette. Do not read [ColorScheme] from application code — use
/// `context.colors` instead.
ColorScheme _colorSchemeFrom(AppColors colors, Brightness brightness) {
  return ColorScheme(
    brightness: brightness,
    primary: colors.wine,
    onPrimary: colors.onWine,
    secondary: colors.gold,
    onSecondary: colors.ink,
    error: colors.bad,
    onError: colors.card,
    surface: colors.card,
    onSurface: colors.ink,
    onSurfaceVariant: colors.ink2,
    outline: colors.rule,
    primaryContainer: colors.paper2,
    onPrimaryContainer: colors.ink,
    secondaryContainer: colors.paper2,
    onSecondaryContainer: colors.ink,
    surfaceContainerHighest: colors.paper2,
  );
}

/// Maps the named type scale onto Material's fixed [TextTheme] slots.
///
/// Same deal as [_colorSchemeFrom]: it keeps stock widgets consistent, and is
/// not meant to be read from application code — use `context.ts` instead.
TextTheme _textThemeFrom(AppTextStyles t) {
  return TextTheme(
    displayLarge: t.h1,
    displayMedium: t.h2,
    displaySmall: t.h3,
    headlineLarge: t.h2,
    headlineMedium: t.h3,
    headlineSmall: t.h4,
    titleLarge: t.appBarTitle,
    titleMedium: t.h4,
    titleSmall: t.paragraphBold,
    labelLarge: t.button,
    labelMedium: t.tab,
    labelSmall: t.kicker,
    bodyLarge: t.paragraph,
    bodyMedium: t.paragraphSmall,
    bodySmall: t.paragraphTiny,
  );
}
