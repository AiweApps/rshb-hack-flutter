import 'package:flutter/material.dart';

import '../constants/app_colors_constants.dart';
import '../constants/app_text_styles_constants.dart';

/// Design-system palette: `context.colors.neutrals900`.
///
/// This is the only sanctioned way to get a colour in the UI. Do not reach for
/// `Theme.of(context).colorScheme` or write `Color(0xFF...)` inline — add the
/// colour to [AppColors] instead.
extension BuildContextColors on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Design-system typography: `context.ts.paragraphSmall`.
///
/// This is the only sanctioned way to get a text style in the UI. Do not reach
/// for `Theme.of(context).textTheme` or build a `TextStyle` inline — add the
/// style to [AppTextStyles] instead.
///
/// Recolour at the call site:
/// ```dart
/// Text('...', style: context.ts.h3.copyWith(color: context.colors.error))
/// ```
extension BuildContextTextStyle on BuildContext {
  AppTextStyles get ts => Theme.of(this).extension<AppTextStyles>()!;
}
