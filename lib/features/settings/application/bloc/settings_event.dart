part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class StartSettings extends SettingsEvent {
  const StartSettings();
}

/// "Try again" on the full-screen error.
final class RetrySettings extends SettingsEvent {
  const RetrySettings();
}

/// Pull-to-refresh: re-read the service status.
final class RefreshStatus extends SettingsEvent {
  const RefreshStatus();
}

final class ThemePressed extends SettingsEvent {
  const ThemePressed();
}

/// The user picked a theme in the dialog.
final class ThemeChanged extends SettingsEvent {
  final AppThemeMode themeMode;

  const ThemeChanged({required this.themeMode});
}

final class LanguagePressed extends SettingsEvent {
  const LanguagePressed();
}

/// The user picked a language in the dialog.
final class LanguageChanged extends SettingsEvent {
  final String languageCode;

  const LanguageChanged({required this.languageCode});
}

/// The service status pill was tapped.
final class StatusTapped extends SettingsEvent {
  const StatusTapped();
}

final class ShowOnboardingPressed extends SettingsEvent {
  const ShowOnboardingPressed();
}

final class AboutPressed extends SettingsEvent {
  const AboutPressed();
}

final class OpenSitePressed extends SettingsEvent {
  const OpenSitePressed();
}

final class ClearHistoryPressed extends SettingsEvent {
  const ClearHistoryPressed();
}

/// The user confirmed the wipe in the dialog.
final class ClearHistoryConfirmed extends SettingsEvent {
  const ClearHistoryConfirmed();
}
