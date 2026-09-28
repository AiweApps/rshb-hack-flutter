import 'package:flutter/material.dart';

import 'app_colors_constants.dart';
import 'app_style_constants.dart';

/// Design-system typography exposed as a [ThemeExtension].
///
/// The typeface is the platform's own (SF on iOS, Roboto on Android): no
/// `fontFamily` is set, so Flutter picks the system default. The scale
/// follows the iOS text styles, which read naturally on both platforms.
/// Access it as `context.ts.paragraph`.
///
/// Adding a style: field → constructor → value in [AppTextStyles.from] →
/// entry in [copyWith].
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  /// Large title: onboarding, empty states — 34 bold.
  final TextStyle h1;

  /// Screen title in a large navigation bar — 28 bold.
  final TextStyle h2;

  /// Title of the best card, sheet titles — 22 bold.
  final TextStyle h3;

  /// Headline: card titles, list titles — 17 semibold.
  final TextStyle h4;

  /// Inline navigation bar title — 17 semibold.
  final TextStyle appBarTitle;

  /// Body — 17 regular.
  final TextStyle paragraph;

  /// Body, emphasised — 17 semibold.
  final TextStyle paragraphBold;

  /// Subheadline: producer, meta lines — 15 regular.
  final TextStyle paragraphSmall;

  /// Footnote: captions, notes — 13 regular.
  final TextStyle paragraphTiny;

  /// Section header above a grouped list — 13 regular, muted.
  final TextStyle kicker;

  /// Button label — 17 semibold.
  final TextStyle button;

  /// Small button label — 15 semibold.
  final TextStyle buttonSmall;

  /// Chip, tab bar and status pill label — 13 medium.
  final TextStyle tab;

  /// Number badge on a bottle frame — 13 bold.
  final TextStyle badge;

  /// Technical values — 12 monospace.
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
      h1: _style(FontSize.s34, FontWeight.w700, 1.2, ink, letterSpacing: 0.4),
      h2: _style(FontSize.s28, FontWeight.w700, 1.2, ink, letterSpacing: 0.36),
      h3: _style(FontSize.s22, FontWeight.w700, 1.25, ink, letterSpacing: 0.35),
      h4: _style(FontSize.s17, FontWeight.w600, 1.3, ink),
      appBarTitle: _style(FontSize.s17, FontWeight.w600, 1.3, ink),
      paragraph: _style(FontSize.s17, FontWeight.w400, 1.35, ink),
      paragraphBold: _style(FontSize.s17, FontWeight.w600, 1.35, ink),
      paragraphSmall: _style(FontSize.s15, FontWeight.w400, 1.35, colors.ink2),
      paragraphTiny: _style(FontSize.s13, FontWeight.w400, 1.35, colors.muted),
      kicker: _style(FontSize.s13, FontWeight.w400, 1.3, colors.muted),
      button: _style(FontSize.s17, FontWeight.w600, 1.3, ink),
      buttonSmall: _style(FontSize.s15, FontWeight.w600, 1.3, ink),
      tab: _style(FontSize.s13, FontWeight.w500, 1.2, ink),
      badge: _style(FontSize.s13, FontWeight.w700, 1.0, colors.onPhoto),
      mono: TextStyle(
        fontFamily: _monoFamily,
        fontSize: FontSize.s12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: colors.ink2,
      ),
    );
  }

  /// The platform monospace face for technical values.
  static const String _monoFamily = 'monospace';

  static TextStyle _style(
    double fontSize,
    FontWeight fontWeight,
    double height,
    Color color, {
    double letterSpacing = 0,
  }) {
    return TextStyle(
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
