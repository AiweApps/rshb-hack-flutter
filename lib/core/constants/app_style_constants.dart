class AppMargin {
  const AppMargin._();

  static const double m8 = 8.0;
  static const double m10 = 10.0;
  static const double m12 = 12.0;
  static const double m14 = 14.0;
  static const double m15 = 15.0;
  static const double m16 = 16.0;
  static const double m18 = 18.0;
  static const double m20 = 20.0;
}

class AppSpaces {
  const AppSpaces._();

  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
}

class AppPadding {
  const AppPadding._();

  static const double p0 = 0.0;
  static const double p2 = 2.0;
  static const double p4 = 4.0;
  static const double p5 = 5.0;
  static const double p6 = 6.0;
  static const double p7 = 7.0;
  static const double p8 = 8.0;
  static const double p9 = 9.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p14 = 14.0;
  static const double p15 = 15.0;
  static const double p16 = 16.0;
  static const double p18 = 18.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p28 = 28.0;
  static const double p30 = 30.0;
  static const double p32 = 32.0;
  static const double p50 = 50.0;
  static const double p60 = 60.0;
  static const double p65 = 65.0;
  static const double p100 = 100.0;

  static const defaultPadding = AppPadding.p16;
}

class AppSize {
  const AppSize._();

  static const double s0 = 0;
  static const double s1 = 1;
  static const double s2 = 2;
  static const double s1_5 = 1.5;
  static const double s2_5 = 2.5;
  static const double s3 = 3.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const int si8 = 8;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s15 = 15.0;
  static const double s16 = 16.0;
  static const double s18 = 18.0;
  static const double s20 = 20.0;
  static const double s22 = 22.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s30 = 30.0;
  static const double s32 = 32.0;
  static const double s36 = 36.0;
  static const double s40 = 40.0;
  static const double s44 = 44.0;
  static const double s45 = 45.0;
  static const double s48 = 48.0;
  static const double s52 = 52.0;
  static const double s56 = 56.0;
  static const double s60 = 60.0;
  static const double s64 = 64.0;
  static const double s65 = 65.0;
  static const double s72 = 72.0;
  static const double s75 = 75.0;
  static const double s80 = 80.0;
  static const double s90 = 90.0;
  static const double s96 = 96.0;
  static const double s100 = 100.0;
  static const double s120 = 120.0;
  static const double s130 = 130.0;
  static const double s140 = 140.0;
  static const double s160 = 160.0;
  static const double s180 = 180.0;
  static const double s190 = 190.0;
  static const double s200 = 200.0;
  static const double s240 = 240.0;
  static const double s250 = 250.0;
  static const double s280 = 280.0;
  static const double s400 = 400.0;

  /// Smallest comfortable touch target (adaptive.md §6).
  static const double minTapTarget = s44;

  /// Height of the pill buttons of the design (44 on the web).
  static const double buttonHeight = s44;
  static const double buttonSmallHeight = s36;

  /// Corner handles of the drawn frame.
  static const double roiHandle = s28;
  static const double roiStroke = s2_5;
  static const double bottleBoxStroke = s3;

  static const double sheetFactor = 0.45;
  static const double defaultCircularProgressSize = 36.0;
  static const double dividerThickness = 1;

  /// The frame and compare sheets, as a share of the screen height.
  static const double resultSheetMax = 0.92;
}

class AppRadius {
  const AppRadius._();

  static const double r0 = 0.0;
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;

  /// Fully rounded ("pill") corners.
  static const double rPill = 999.0;

  /// The iOS icon mask, at the 120pt launch logo (22% of the side).
  static const double rLaunchLogo = 26.4;
}

class AppAlpha {
  const AppAlpha._();

  /// Opacity of 8%
  static const int a8 = 20;

  /// Opacity of 12%
  static const int a12 = 31;

  /// Opacity of 20%
  static const int a20 = 51;

  /// Opacity of 30%
  static const int a30 = 77;

  /// Opacity of 40%
  static const int a40 = 102;

  /// Opacity of 50%
  static const int a50 = 128;

  /// Opacity of 70%
  static const int a70 = 179;

  /// Opacity of 75%
  static const int a75 = 191;

  /// Opacity of 85%
  static const int a85 = 217;
}

class FontSize {
  const FontSize._();

  static const double s11 = 11.0;
  static const double s12 = 12.0;
  static const double s13 = 13.0;
  static const double s14 = 14.0;
  static const double s15 = 15.0;
  static const double s16 = 16.0;
  static const double s17 = 17.0;
  static const double s18 = 18.0;
  static const double s20 = 20.0;
  static const double s21 = 21.0;
  static const double s22 = 22.0;
  static const double s24 = 24.0;
  static const double s26 = 26.0;
  static const double s28 = 28.0;
  static const double s30 = 30.0;
  static const double s34 = 34.0;
}
