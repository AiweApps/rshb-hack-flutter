import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors_constants.dart';
import 'app_style_constants.dart';

/// Design-system typography exposed as a [ThemeExtension].
///
/// The scale follows the web UI: PT Serif Caption for display headings,
/// PT Serif for reading text, PT Sans Narrow (upper case) for controls, and
/// PT Mono for technical values. Access it as `context.ts.paragraph`.
///
/// Upper-casing is not part of a style; the control widgets apply it to their
/// label, so the ARB strings stay readable.
///
/// Adding a style: field → constructor → value in [AppTextStyles.from] →
/// entry in [copyWith].
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  /// Screen title on the landing and onboarding — 34sp display bold.
  final TextStyle h1;

  /// Section title — 28sp display bold.
  final TextStyle h2;

  /// Card title of the best match — 22sp display bold.
  final TextStyle h3;

  /// Card title of an alternative, list titles — 18sp serif bold.
  final TextStyle h4;

  /// App bar title — 20sp display bold.
  final TextStyle appBarTitle;

  /// Reading text — 17sp serif.
  final TextStyle paragraph;

  /// Reading text, bold — 17sp serif bold.
  final TextStyle paragraphBold;

  /// Secondary text: producer, meta line — 15sp serif.
  final TextStyle paragraphSmall;

  /// Captions under photos, notes — 13sp serif.
  final TextStyle paragraphTiny;

  /// Small upper-case label above a title — 11sp narrow bold, wide tracking.
  final TextStyle kicker;

  /// Primary and ghost button label — 15sp narrow semibold.
  final TextStyle button;

  /// Small button label — 13sp narrow semibold.
  final TextStyle buttonSmall;

  /// Tab / chip label, status pill — 14sp narrow semibold.
  final TextStyle tab;

  /// Number badge on a bottle frame — 14sp narrow bold.
  final TextStyle badge;

  /// Technical values — 12sp mono.
  final TextStyle mono;

  const AppTextStyles({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.appBarTitle,
    required this.paragraph,
    required this.paragraphBold,
    required this.paragraphSmall,
    required this.paragraphTiny,
    required this.kicker,
    required this.button,
    required this.buttonSmall,
    required this.tab,
    required this.badge,
    required this.mono,
  });

  /// Builds the type scale on top of a palette, so light and dark share one
  /// definition and differ only by the colours they are given.
  factory AppTextStyles.from(AppColors colors) {
    final Color ink = colors.ink;

    return AppTextStyles(
      h1: _display(FontSize.s34, FontWeight.w700, 1.1, ink),
      h2: _display(FontSize.s28, FontWeight.w700, 1.15, ink),
      h3: _display(FontSize.s22, FontWeight.w700, 1.2, ink),
      h4: _text(FontSize.s18, FontWeight.w700, 1.25, ink),
      appBarTitle: _display(FontSize.s20, FontWeight.w700, 1.2, ink),
      paragraph: _text(FontSize.s17, FontWeight.w400, 1.5, ink),
      paragraphBold: _text(FontSize.s17, FontWeight.w700, 1.5, ink),
      paragraphSmall: _text(FontSize.s15, FontWeight.w400, 1.45, colors.ink2),
      paragraphTiny: _text(FontSize.s13, FontWeight.w400, 1.4, colors.muted),
      kicker: _ui(
        FontSize.s11,
        FontWeight.w700,
        1.2,
        colors.muted,
        letterSpacing: _kickerLetterSpacing,
      ),
      button: _ui(
        FontSize.s15,
        FontWeight.w600,
        1.0,
        ink,
        letterSpacing: _buttonLetterSpacing,
      ),
      buttonSmall: _ui(
        FontSize.s13,
        FontWeight.w600,
        1.0,
        ink,
        letterSpacing: _buttonLetterSpacing,
      ),
      tab: _ui(
        FontSize.s14,
        FontWeight.w600,
        1.0,
        ink,
        letterSpacing: _tabLetterSpacing,
      ),
      badge: _ui(FontSize.s14, FontWeight.w700, 1.0, colors.onPhoto),
      mono: GoogleFonts.ptMono(
        fontSize: FontSize.s12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: colors.ink2,
      ),
    );
  }

  static const double _kickerLetterSpacing = 1.76;
  static const double _buttonLetterSpacing = 0.6;
  static const double _tabLetterSpacing = 0.28;

  /// Display face for headings.
  static TextStyle _display(
    double fontSize,
    FontWeight fontWeight,
    double height,
    Color color,
  ) {
    return GoogleFonts.ptSerifCaption(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Reading face.
  static TextStyle _text(
    double fontSize,
    FontWeight fontWeight,
    double height,
    Color color,
  ) {
    return GoogleFonts.ptSerif(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Control face: buttons, tabs, kickers.
  static TextStyle _ui(
    double fontSize,
    FontWeight fontWeight,
    double height,
    Color color, {
    double letterSpacing = 0,
  }) {
    return GoogleFonts.ptSansNarrow(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  @override
  AppTextStyles copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? appBarTitle,
    TextStyle? paragraph,
    TextStyle? paragraphBold,
    TextStyle? paragraphSmall,
    TextStyle? paragraphTiny,
    TextStyle? kicker,
    TextStyle? button,
    TextStyle? buttonSmall,
    TextStyle? tab,
    TextStyle? badge,
    TextStyle? mono,
  }) {
    return AppTextStyles(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      paragraph: paragraph ?? this.paragraph,
      paragraphBold: paragraphBold ?? this.paragraphBold,
      paragraphSmall: paragraphSmall ?? this.paragraphSmall,
      paragraphTiny: paragraphTiny ?? this.paragraphTiny,
      kicker: kicker ?? this.kicker,
      button: button ?? this.button,
      buttonSmall: buttonSmall ?? this.buttonSmall,
      tab: tab ?? this.tab,
      badge: badge ?? this.badge,
      mono: mono ?? this.mono,
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
