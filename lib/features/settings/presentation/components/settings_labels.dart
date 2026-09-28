import 'package:flutter/widgets.dart';

import '../../../../core/services/language_service.dart';
import '../../../../core/services/theme_service.dart';

/// Language codes the picker knows a name for. Russian is the product
/// language and the default, so anything else falls back to it.
const String _englishLanguageCode = 'en';

/// What the theme row and the theme picker call each [AppThemeMode].
String themeModeLabel(BuildContext context, AppThemeMode mode) {
  final l10n = context.localization;
  return switch (mode) {
    AppThemeMode.system => l10n.themeSystem,
    AppThemeMode.light => l10n.themeLight,
    AppThemeMode.dark => l10n.themeDark,
  };
}

/// What the language row and the language picker call a language code.
String languageLabel(BuildContext context, String languageCode) {
  final l10n = context.localization;
  return switch (languageCode) {
    _englishLanguageCode => l10n.languageEnglish,
    _ => l10n.languageRussian,
  };
}
