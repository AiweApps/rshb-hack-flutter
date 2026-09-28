import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../shared/domain/service_availability.dart';
import '../../../../shared/presentation/errors/error_type.dart';

part 'settings_state.freezed.dart';

/// Everything the settings tab draws.
///
/// [screenStatus] is `content` as soon as the bloc starts: the theme and the
/// language are read synchronously, and the service status arrives later
/// into [serviceState] without ever taking the screen down.
@freezed
abstract class SettingsState with _$SettingsState implements BaseBlocState {
  const factory SettingsState({
    required ScreenStatus screenStatus,
    required ErrorType? errorType,
    required AppThemeMode themeMode,
    required String languageCode,
    required ServiceState serviceState,

    /// Size of the wine catalogue on the server, when the status told it.
    required int? catalogCards,

    /// Pull-to-refresh of the service status is in flight.
    required bool isRefreshing,

    /// The history is being wiped; a second confirm is ignored meanwhile.
    required bool isClearingHistory,

    /// "1.0.0" and "12" from the package info, once read.
    required String? version,
    required String? buildNumber,
  }) = _SettingsState;

  factory SettingsState.initial() => const SettingsState(
    screenStatus: ScreenStatus.loading,
    errorType: null,
    themeMode: AppThemeMode.system,
    languageCode: LanguageService.defaultLanguageCode,
    serviceState: ServiceState.checking,
    catalogCards: null,
    isRefreshing: false,
    isClearingHistory: false,
    version: null,
    buildNumber: null,
  );
}
