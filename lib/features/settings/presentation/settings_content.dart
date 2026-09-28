import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/language_service.dart';
import '../../../shared/presentation/service_status_pill.dart';
import '../application/bloc/settings_bloc.dart';
import '../application/bloc/settings_state.dart';
import 'components/settings_labels.dart';
import 'components/settings_row.dart';
import 'components/settings_section.dart';

class SettingsContent extends StatelessWidget {
  final SettingsState state;

  const SettingsContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final bloc = context.read<SettingsBloc>();
    final int? catalogCards = state.catalogCards;

    return RefreshIndicator(
      onRefresh: () => _refresh(bloc),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16,
          vertical: AppPadding.p16,
        ),
        children: [
          SettingsSection(
            title: l10n.settingsAppearance,
            children: [
              SettingsRow(
                icon: Icons.brightness_6_outlined,
                title: l10n.settingsTheme,
                value: themeModeLabel(context, state.themeMode),
                onTap: () => bloc.add(const ThemePressed()),
              ),
              SettingsRow(
                icon: Icons.language_outlined,
                title: l10n.settingsLanguage,
                value: languageLabel(context, state.languageCode),
                onTap: () => bloc.add(const LanguagePressed()),
              ),
            ],
          ),
          const SizedBox(height: AppSpaces.s24),
          SettingsSection(
            title: l10n.settingsService,
            children: [
              SettingsRow(
                icon: Icons.cloud_outlined,
                title: l10n.settingsService,
                subtitle: catalogCards == null
                    ? null
                    : l10n.settingsCatalogSize(catalogCards),
                trailing: ServiceStatusPill(
                  state: state.serviceState,
                  onTap: () => bloc.add(const StatusTapped()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpaces.s24),
          SettingsSection(
            title: l10n.settingsHelp,
            children: [
              SettingsRow(
                icon: Icons.play_circle_outline,
                title: l10n.settingsShowOnboarding,
                onTap: () => bloc.add(const ShowOnboardingPressed()),
              ),
              SettingsRow(
                icon: Icons.info_outline,
                title: l10n.settingsAbout,
                onTap: () => bloc.add(const AboutPressed()),
              ),
              SettingsRow(
                icon: Icons.language,
                title: l10n.settingsOpenSite,
                trailing: Icon(
                  Icons.open_in_new,
                  size: AppSize.s20,
                  color: context.colors.muted,
                ),
                onTap: () => bloc.add(const OpenSitePressed()),
              ),
            ],
          ),
          const SizedBox(height: AppSpaces.s24),
          SettingsSection(
            title: l10n.settingsData,
            children: [
              SettingsRow(
                icon: Icons.delete_outline,
                title: l10n.historyClear,
                color: context.colors.bad,
                onTap: state.isClearingHistory
                    ? null
                    : () => bloc.add(const ClearHistoryPressed()),
              ),
            ],
          ),
          const SizedBox(height: AppSpaces.s32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
            child: Text(
              l10n.disclaimer,
              style: context.ts.paragraphTiny,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// [RefreshIndicator] keeps spinning until the returned future completes,
  /// so it waits for the bloc to report the refresh finished.
  Future<void> _refresh(SettingsBloc bloc) {
    bloc.add(const RefreshStatus());
    return bloc.stream.firstWhere((state) => !state.isRefreshing);
  }
}
