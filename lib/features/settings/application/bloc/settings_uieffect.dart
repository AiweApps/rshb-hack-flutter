import '../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../shared/domain/service_availability.dart';

sealed class SettingsUiEffect extends BaseBlocUiEffect {}

/// Show the theme picker with [current] highlighted.
final class PickTheme extends SettingsUiEffect {
  final AppThemeMode current;

  PickTheme({required this.current});
}

/// Show the language picker: [languageCodes] to choose from, [current]
/// highlighted.
final class PickLanguage extends SettingsUiEffect {
  final String current;
  final List<String> languageCodes;

  PickLanguage({required this.current, required this.languageCodes});
}

/// Open the sheet explaining what the status pill means right now.
final class ShowServiceDetail extends SettingsUiEffect {
  final ServiceAvailability availability;

  ShowServiceDetail({required this.availability});
}

final class OpenOnboarding extends SettingsUiEffect {}

final class ShowAbout extends SettingsUiEffect {}

/// Open [url] in the system browser.
final class OpenExternalUrl extends SettingsUiEffect {
  final String url;

  OpenExternalUrl({required this.url});
}

/// Ask before wiping the history; the answer comes back as an event.
final class ConfirmClearHistory extends SettingsUiEffect {}
