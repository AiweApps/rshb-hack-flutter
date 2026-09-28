import 'package:flutter/material.dart';

/// Design-system palette exposed as a [ThemeExtension].
///
/// Access it from any widget:
/// ```dart
/// final appColors = Theme.of(context).extension<AppColors>()!;
/// ```
///
/// Registered in `getBaseTheme` for both brightnesses. The `dark` variant
/// currently mirrors `light` — override the values once the dark design is
/// defined.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary100;
  final Color primary200;
  final Color primary300;
  final Color primary400;
  final Color primary500;

  final Color neutrals100;
  final Color neutrals200;
  final Color neutrals300;
  final Color neutrals400;
  final Color neutrals500;
  final Color neutrals600;
  final Color neutrals700;
  final Color neutrals800;
  final Color neutrals900;

  final Color red;
  final Color grey;
  final Color error;
  final Color delete;
  final Color success;
  final Color azure100;

  final Color chipBackground;
  final Color darkCardBackground;
  final Color headerBlackBackground;

  final Color toastSuccess;
  final Color toastError;

  const AppColors({
    required this.primary100,
    required this.primary200,
    required this.primary300,
    required this.primary400,
    required this.primary500,
    required this.neutrals100,
    required this.neutrals200,
    required this.neutrals300,
    required this.neutrals400,
    required this.neutrals500,
    required this.neutrals600,
    required this.neutrals700,
    required this.neutrals800,
    required this.neutrals900,
    required this.red,
    required this.grey,
    required this.error,
    required this.delete,
    required this.success,
    required this.azure100,
    required this.chipBackground,
    required this.darkCardBackground,
    required this.headerBlackBackground,
    required this.toastSuccess,
    required this.toastError,
  });

  static const light = AppColors(
    primary100: Color(0xFFFFF3BD),
    primary200: Color(0xFFFFEAA2),
    primary300: Color(0xFFFFE187),
    primary400: Color(0xFFFFD861),
    primary500: Color(0xFFFFA100),
    neutrals100: Color(0xFFFFFFFF),
    neutrals200: Color(0xFFFCFCFD),
    neutrals300: Color(0xFFF4F5F6),
    neutrals400: Color(0xFFE6E8EC),
    neutrals500: Color(0xFFB1B5C3),
    neutrals600: Color(0xFF777E90),
    neutrals700: Color(0xFF353945),
    neutrals800: Color(0xFF23262F),
    neutrals900: Color(0xFF141416),
    red: Color(0xFFFF3B30),
    grey: Color(0xFFAAAAAA),
    error: Color(0xFFF62F56),
    delete: Color(0xFFE02E2E),
    success: Color(0xFF00C8B3),
    azure100: Color(0xFF0077FF),
    chipBackground: Color(0xFFF4F5F8),
    darkCardBackground: Color(0xFF222224),
    headerBlackBackground: Color(0xFF16191A),
    toastSuccess: Color(0xFFD6FFBE),
    toastError: Color(0xFFFFBEBF),
  );

  static const dark = AppColors(
    primary100: Color(0xFFFFEAA2),
    primary200: Color(0xFFFFEAA2),
    primary300: Color(0xFFFFE187),
    primary400: Color(0xFFFFD861),
    primary500: Color(0xFFFFA100),
    neutrals100: Color(0xFFFFFFFF),
    neutrals200: Color(0xFFFCFCFD),
    neutrals300: Color(0xFFF4F5F6),
    neutrals400: Color(0xFFE6E8EC),
    neutrals500: Color(0xFFB1B5C3),
    neutrals600: Color(0xFF777E90),
    neutrals700: Color(0xFF353945),
    neutrals800: Color(0xFF23262F),
    neutrals900: Color(0xFF141416),
    red: Color(0xFFFF3B30),
    grey: Color(0xFFAAAAAA),
    error: Color(0xFFF62F56),
    delete: Color(0xFFE02E2E),
    success: Color(0xFF00C8B3),
    azure100: Color(0xFF0077FF),
    chipBackground: Color(0xFFF4F5F8),
    darkCardBackground: Color(0xFF222224),
    headerBlackBackground: Color(0xFF16191A),
    toastSuccess: Color(0xFFD6FFBE),
    toastError: Color(0xFFFFBEBF),
  );

  @override
  AppColors copyWith({
    Color? primary100,
    Color? primary200,
    Color? primary300,
    Color? primary400,
    Color? primary500,
    Color? neutrals100,
    Color? neutrals200,
    Color? neutrals300,
    Color? neutrals400,
    Color? neutrals500,
    Color? neutrals600,
    Color? neutrals700,
    Color? neutrals800,
    Color? neutrals900,
    Color? red,
    Color? grey,
    Color? error,
    Color? delete,
    Color? success,
    Color? azure100,
    Color? chipBackground,
    Color? darkCardBackground,
    Color? headerBlackBackground,
    Color? toastSuccess,
    Color? toastError,
  }) {
    return AppColors(
      primary100: primary100 ?? this.primary100,
      primary200: primary200 ?? this.primary200,
      primary300: primary300 ?? this.primary300,
      primary400: primary400 ?? this.primary400,
      primary500: primary500 ?? this.primary500,
      neutrals100: neutrals100 ?? this.neutrals100,
      neutrals200: neutrals200 ?? this.neutrals200,
      neutrals300: neutrals300 ?? this.neutrals300,
      neutrals400: neutrals400 ?? this.neutrals400,
      neutrals500: neutrals500 ?? this.neutrals500,
      neutrals600: neutrals600 ?? this.neutrals600,
      neutrals700: neutrals700 ?? this.neutrals700,
      neutrals800: neutrals800 ?? this.neutrals800,
      neutrals900: neutrals900 ?? this.neutrals900,
      red: red ?? this.red,
      grey: grey ?? this.grey,
      error: error ?? this.error,
      delete: delete ?? this.delete,
      success: success ?? this.success,
      azure100: azure100 ?? this.azure100,
      chipBackground: chipBackground ?? this.chipBackground,
      darkCardBackground: darkCardBackground ?? this.darkCardBackground,
      headerBlackBackground:
          headerBlackBackground ?? this.headerBlackBackground,
      toastSuccess: toastSuccess ?? this.toastSuccess,
      toastError: toastError ?? this.toastError,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary100: Color.lerp(primary100, other.primary100, t)!,
      primary200: Color.lerp(primary200, other.primary200, t)!,
      primary300: Color.lerp(primary300, other.primary300, t)!,
      primary400: Color.lerp(primary400, other.primary400, t)!,
      primary500: Color.lerp(primary500, other.primary500, t)!,
      neutrals100: Color.lerp(neutrals100, other.neutrals100, t)!,
      neutrals200: Color.lerp(neutrals200, other.neutrals200, t)!,
      neutrals300: Color.lerp(neutrals300, other.neutrals300, t)!,
      neutrals400: Color.lerp(neutrals400, other.neutrals400, t)!,
      neutrals500: Color.lerp(neutrals500, other.neutrals500, t)!,
      neutrals600: Color.lerp(neutrals600, other.neutrals600, t)!,
      neutrals700: Color.lerp(neutrals700, other.neutrals700, t)!,
      neutrals800: Color.lerp(neutrals800, other.neutrals800, t)!,
      neutrals900: Color.lerp(neutrals900, other.neutrals900, t)!,
      red: Color.lerp(red, other.red, t)!,
      grey: Color.lerp(grey, other.grey, t)!,
      error: Color.lerp(error, other.error, t)!,
      delete: Color.lerp(delete, other.delete, t)!,
      success: Color.lerp(success, other.success, t)!,
      azure100: Color.lerp(azure100, other.azure100, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      darkCardBackground: Color.lerp(
        darkCardBackground,
        other.darkCardBackground,
        t,
      )!,
      headerBlackBackground: Color.lerp(
        headerBlackBackground,
        other.headerBlackBackground,
        t,
      )!,
      toastSuccess: Color.lerp(toastSuccess, other.toastSuccess, t)!,
      toastError: Color.lerp(toastError, other.toastError, t)!,
    );
  }
}
