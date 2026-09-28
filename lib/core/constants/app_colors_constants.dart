import 'package:flutter/material.dart';

/// Design-system palette exposed as a [ThemeExtension].
///
/// The names and values are the ones of the «Винный сканер» web UI
/// (`static/app.css`): paper and card surfaces, ink for text, wine for
/// actions, gold for accents. Access it as `context.colors.wine`.
///
/// Adding a colour: field → constructor → `light` and `dark` values →
/// `copyWith` → `lerp`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Page background.
  final Color paper;

  /// Slightly deeper background: sheets, chips, inactive tabs.
  final Color paper2;

  /// Surface of cards and dialogs.
  final Color card;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color ink2;

  /// Captions, hints, placeholders.
  final Color muted;

  /// Hairlines, borders.
  final Color rule;

  /// Brand colour: primary buttons, links, active state.
  final Color wine;

  /// Pressed / hovered brand colour.
  final Color wine2;

  /// Text and icons on a wine-filled surface.
  final Color onWine;

  /// Accent: focus rings, selected frame, step numerals.
  final Color gold;

  /// Service is ready.
  final Color ok;

  /// Service is busy; warnings.
  final Color warn;

  /// Errors; service down.
  final Color bad;

  /// Badges drawn over a photo: white on any theme.
  final Color onPhoto;

  /// Scrim over a photo (draw mode, viewer).
  final Color scrim;

  final Color toastInfo;
  final Color toastSuccess;
  final Color toastError;

  const AppColors({
    required this.paper,
    required this.paper2,
    required this.card,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.rule,
    required this.wine,
    required this.wine2,
    required this.onWine,
    required this.gold,
    required this.ok,
    required this.warn,
    required this.bad,
    required this.onPhoto,
    required this.scrim,
    required this.toastInfo,
    required this.toastSuccess,
    required this.toastError,
  });

  static const light = AppColors(
    paper: Color(0xFFF3ECDF),
    paper2: Color(0xFFEBE1CF),
    card: Color(0xFFFBF7EF),
    ink: Color(0xFF26181A),
    ink2: Color(0xFF5A4A45),
    muted: Color(0xFF86766E),
    rule: Color(0xFFD6C8B2),
    wine: Color(0xFF6B1D2C),
    wine2: Color(0xFF8C2A3C),
    onWine: Color(0xFFFBF7EF),
    gold: Color(0xFFA9853F),
    ok: Color(0xFF3F6B3A),
    warn: Color(0xFF9A6516),
    bad: Color(0xFF9B2B2B),
    onPhoto: Color(0xFFFFFFFF),
    scrim: Color(0xFF26181A),
    toastInfo: Color(0xFFEBE1CF),
    toastSuccess: Color(0xFFDCE9D8),
    toastError: Color(0xFFF1D6D3),
  );

  static const dark = AppColors(
    paper: Color(0xFF16100F),
    paper2: Color(0xFF1F1715),
    card: Color(0xFF231A18),
    ink: Color(0xFFEFE4D3),
    ink2: Color(0xFFCBBBA6),
    muted: Color(0xFF9A8A7C),
    rule: Color(0xFF3A2D29),
    wine: Color(0xFFD77A88),
    wine2: Color(0xFFE9909C),
    onWine: Color(0xFF16100F),
    gold: Color(0xFFD0AB62),
    ok: Color(0xFF8FBF83),
    warn: Color(0xFFE0A64A),
    bad: Color(0xFFEC8B84),
    onPhoto: Color(0xFFFFFFFF),
    scrim: Color(0xFF000000),
    toastInfo: Color(0xFF2B211E),
    toastSuccess: Color(0xFF2E3F2B),
    toastError: Color(0xFF4A2A28),
  );

  @override
  AppColors copyWith({
    Color? paper,
    Color? paper2,
    Color? card,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? rule,
    Color? wine,
    Color? wine2,
    Color? onWine,
    Color? gold,
    Color? ok,
    Color? warn,
    Color? bad,
    Color? onPhoto,
    Color? scrim,
    Color? toastInfo,
    Color? toastSuccess,
    Color? toastError,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      paper2: paper2 ?? this.paper2,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      rule: rule ?? this.rule,
      wine: wine ?? this.wine,
      wine2: wine2 ?? this.wine2,
      onWine: onWine ?? this.onWine,
      gold: gold ?? this.gold,
      ok: ok ?? this.ok,
      warn: warn ?? this.warn,
      bad: bad ?? this.bad,
      onPhoto: onPhoto ?? this.onPhoto,
      scrim: scrim ?? this.scrim,
      toastInfo: toastInfo ?? this.toastInfo,
      toastSuccess: toastSuccess ?? this.toastSuccess,
      toastError: toastError ?? this.toastError,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      wine: Color.lerp(wine, other.wine, t)!,
      wine2: Color.lerp(wine2, other.wine2, t)!,
      onWine: Color.lerp(onWine, other.onWine, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      onPhoto: Color.lerp(onPhoto, other.onPhoto, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      toastInfo: Color.lerp(toastInfo, other.toastInfo, t)!,
      toastSuccess: Color.lerp(toastSuccess, other.toastSuccess, t)!,
      toastError: Color.lerp(toastError, other.toastError, t)!,
    );
  }
}
