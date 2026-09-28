import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors_constants.dart';
import 'app_style_constants.dart';

/// Design-system typography exposed as a [ThemeExtension].
///
/// This — not Flutter's [TextTheme] — is the source of truth for text styles.
/// Styles carry the names used in the design file, so a call site says what it
/// means: `context.ts.h2`, not `context.textStyle.displayMedium`.
///
/// Access it from any widget through the `BuildContextTextStyle` extension:
/// ```dart
/// Text('...', style: context.ts.paragraphSmall)
/// Text('...', style: context.ts.h3.copyWith(color: context.colors.error))
/// ```
///
/// Registered in `getBaseTheme` for both brightnesses. The [TextTheme] inside
/// `ThemeData` is derived from these tokens purely so that stock Material
/// widgets stay in sync — application code must not read it.
///
/// Adding a style: add the field, the constructor argument, the value in
/// [AppTextStyles.from] and the entry in [copyWith].
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  /// "H1" — 30sp extra bold.
  final TextStyle h1;

  /// "H2" — 24sp medium.
  final TextStyle h2;

  /// "H3" — 21sp medium.
  final TextStyle h3;

  /// "H4" — 18sp extra bold.
  final TextStyle h4;

  /// "Paragraph Large Bold" — 24sp bold.
  final TextStyle paragraphLargeBold;

  /// "Fieldset Label" — 21sp medium.
  final TextStyle fieldsetLabel;

  /// "Timer Large" — 60sp black.
  final TextStyle timerLarge;

  /// "Timer" — 21sp black.
  final TextStyle timer;

  /// App bar title only — 21sp black.
  final TextStyle appBarTitle;

  /// "Paragraph Bold" — 18sp bold.
  final TextStyle paragraphBold;

  /// "Paragraph Small Bold" — 15sp bold.
  final TextStyle paragraphSmallBold;

  /// "Paragraph Tiny Bold" — 12sp bold.
  final TextStyle paragraphTinyBold;

  /// "Paragraph" / "Label" — 18sp regular.
  final TextStyle paragraph;

  /// "Paragraph Small" / "Label Small" — 15sp regular.
  final TextStyle paragraphSmall;

  /// "Paragraph Tiny" — 12sp regular.
  final TextStyle paragraphTiny;

  const AppTextStyles({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.paragraphLargeBold,
    required this.fieldsetLabel,
    required this.timerLarge,
    required this.timer,
    required this.appBarTitle,
    required this.paragraphBold,
    required this.paragraphSmallBold,
    required this.paragraphTinyBold,
    required this.paragraph,
    required this.paragraphSmall,
    required this.paragraphTiny,
  });

  /// Builds the type scale on top of a palette, so light and dark share one
  /// definition and differ only by the colours they are given.
  factory AppTextStyles.from(AppColors colors) {
    final Color defaultColor = colors.neutrals900;

    return AppTextStyles(
      h1: _style(FontSize.s30, FontWeight.w800, 36, defaultColor),
      h2: _style(FontSize.s24, FontWeight.w500, 28.8, defaultColor),
      h3: _style(FontSize.s21, FontWeight.w500, 25.2, defaultColor),
      h4: _style(FontSize.s18, FontWeight.w800, 21.6, defaultColor),
      paragraphLargeBold: _style(
        FontSize.s24,
        FontWeight.w700,
        28.8,
        defaultColor,
      ),
      fieldsetLabel: _style(FontSize.s21, FontWeight.w500, 25.2, defaultColor),
      timerLarge: _style(FontSize.s60, FontWeight.w900, 72, defaultColor),
      timer: _style(FontSize.s21, FontWeight.w900, 25.2, defaultColor),
      appBarTitle: _style(FontSize.s21, FontWeight.w900, 25.2, defaultColor),
      paragraphBold: _style(FontSize.s18, FontWeight.w700, 21.6, defaultColor),
      paragraphSmallBold: _style(
        FontSize.s15,
        FontWeight.w700,
        18,
        defaultColor,
      ),
      paragraphTinyBold: _style(
        FontSize.s12,
        FontWeight.w700,
        14.4,
        defaultColor,
      ),
      paragraph: _style(FontSize.s18, FontWeight.w400, 21.6, defaultColor),
      paragraphSmall: _style(FontSize.s15, FontWeight.w400, 18, defaultColor),
      paragraphTiny: _style(FontSize.s12, FontWeight.w400, 14.4, defaultColor),
    );
  }

  /// The app font. Changing the typeface is a one-line change here.
  ///
  /// [lineHeight] is the absolute line height from the design file; Flutter
  /// wants it as a multiplier, hence the division.
  static TextStyle _style(
    double fontSize,
    FontWeight fontWeight,
    double lineHeight,
    Color color, {
    double letterSpacing = _defaultLetterSpacing,
  }) {
    return GoogleFonts.lato(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: lineHeight / fontSize,
    );
  }

  static const double _defaultLetterSpacing = 0.04;

  @override
  AppTextStyles copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? paragraphLargeBold,
    TextStyle? fieldsetLabel,
    TextStyle? timerLarge,
    TextStyle? timer,
    TextStyle? appBarTitle,
    TextStyle? paragraphBold,
    TextStyle? paragraphSmallBold,
    TextStyle? paragraphTinyBold,
    TextStyle? paragraph,
    TextStyle? paragraphSmall,
    TextStyle? paragraphTiny,
  }) {
    return AppTextStyles(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      paragraphLargeBold: paragraphLargeBold ?? this.paragraphLargeBold,
      fieldsetLabel: fieldsetLabel ?? this.fieldsetLabel,
      timerLarge: timerLarge ?? this.timerLarge,
      timer: timer ?? this.timer,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      paragraphBold: paragraphBold ?? this.paragraphBold,
      paragraphSmallBold: paragraphSmallBold ?? this.paragraphSmallBold,
      paragraphTinyBold: paragraphTinyBold ?? this.paragraphTinyBold,
      paragraph: paragraph ?? this.paragraph,
      paragraphSmall: paragraphSmall ?? this.paragraphSmall,
      paragraphTiny: paragraphTiny ?? this.paragraphTiny,
    );
  }

  /// Type does not interpolate: animating font size and weight mid-transition
  /// looks like a glitch, so the scale flips once at the halfway point. Colours
  /// still animate smoothly — they come from [AppColors].
  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return t < 0.5 ? this : other;
  }
}
