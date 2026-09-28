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

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: _textThemeFrom(textStyles),
    scaffoldBackgroundColor: colors.neutrals100,
    splashColor: colors.neutrals100.withAlpha(AppAlpha.a70),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: colors.primary500,
      surfaceTintColor: colors.primary500,
      height: AppSize.s100,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      surfaceTintColor: colors.neutrals100,
      backgroundColor: colors.neutrals100,
      titleTextStyle: textStyles.appBarTitle,
    ),
    dividerTheme: DividerThemeData(
      thickness: AppSize.dividerThickness,
      color: colors.neutrals400,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colors.neutrals900,
      unselectedLabelColor: colors.neutrals900.withAlpha(AppAlpha.a30),
      indicatorColor: colors.neutrals900,
      overlayColor: WidgetStatePropertyAll(
        colors.neutrals900.withAlpha(AppAlpha.a30),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: colors.neutrals900,
      titleTextStyle: textStyles.h4,
      subtitleTextStyle: textStyles.paragraph,
      iconColor: colors.neutrals900,
      tileColor: colors.neutrals100,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.neutrals100,
      iconColor: colors.neutrals900,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.neutrals900,
      strokeWidth: 1.5,
    ),
    // For buttons with text and icon
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll<Color>(colors.neutrals100),
        backgroundColor: WidgetStatePropertyAll<Color>(colors.neutrals900),
        overlayColor: WidgetStatePropertyAll<Color>(
          colors.neutrals100.withAlpha(AppAlpha.a30),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          textStyles.paragraphSmall,
        ),
        minimumSize: const WidgetStatePropertyAll<Size?>(
          Size.fromHeight(AppSize.s75),
        ),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    ),
    // For buttons with text only
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(double.minPositive, AppSize.s45),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(colors.neutrals900),
        backgroundColor: WidgetStatePropertyAll<Color>(colors.neutrals100),
        overlayColor: WidgetStatePropertyAll<Color>(
          colors.neutrals900.withAlpha(AppAlpha.a30),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          textStyles.paragraphSmall,
        ),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    ),
    // For "secondary" buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll<Size>(
          Size(double.infinity, AppSize.s45),
        ),
        foregroundColor: WidgetStatePropertyAll(colors.neutrals900),
        backgroundColor: WidgetStatePropertyAll(colors.primary500),
        overlayColor: WidgetStatePropertyAll<Color>(
          colors.neutrals900.withAlpha(AppAlpha.a30),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          textStyles.paragraphSmall,
        ),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: colors.neutrals900),
        ),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        return colors.neutrals900;
      }),
      trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primary100;
        }
        // Color for disabled state
        return colors.neutrals400;
      }),
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
    primary: colors.neutrals900,
    onPrimary: colors.neutrals100,
    secondary: colors.primary500,
    onSecondary: colors.neutrals900,
    error: colors.error,
    onError: colors.neutrals100,
    surface: colors.neutrals100,
    onSurface: colors.neutrals900,
    outline: colors.neutrals400,
    primaryContainer: colors.neutrals300,
    onPrimaryContainer: colors.neutrals900,
    secondaryContainer: colors.primary100,
    onSecondaryContainer: colors.neutrals900,
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
    headlineLarge: t.h4,
    headlineMedium: t.paragraphLargeBold,
    headlineSmall: t.fieldsetLabel,
    titleLarge: t.timerLarge,
    titleMedium: t.timer,
    titleSmall: t.appBarTitle,
    labelLarge: t.paragraphBold,
    labelMedium: t.paragraphSmallBold,
    labelSmall: t.paragraphTinyBold,
    bodyLarge: t.paragraph,
    bodyMedium: t.paragraphSmall,
    bodySmall: t.paragraphTiny,
  );
}
