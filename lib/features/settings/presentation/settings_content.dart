import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/presentation/app_icons.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/navigation/nav_bar_height_provider.dart';
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
        padding: EdgeInsets.fromLTRB(
          AppPadding.p16,
          AppPadding.p16,
          AppPadding.p16,
          (NavBarHeightProvider.maybeOf(context) ?? 0) + AppPadding.p16,
        ),
        children: [
          SettingsSection(
            title: l10n.settingsAppearance,
            children: [
              SettingsRow(
                icon: AppIcon.appearance.data,
                title: l10n.settingsTheme,
                value: themeModeLabel(context, state.themeMode),
                onTap: () => bloc.add(const ThemePressed()),
              ),
              SettingsRow(
                icon: AppIcon.language.data,
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
                icon: AppIcon.cloud.data,
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
                icon: AppIcon.play.data,
                title: l10n.settingsShowOnboarding,
                onTap: () => bloc.add(const ShowOnboardingPressed()),
              ),
              SettingsRow(
                icon: AppIcon.info.data,
                title: l10n.settingsAbout,
                onTap: () => bloc.add(const AboutPressed()),
              ),
              SettingsRow(
                icon: AppIcon.language.data,
                title: l10n.settingsOpenSite,
                trailing: Icon(
                  AppIcon.openExternal.data,
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
                icon: AppIcon.delete.data,
                title: l10n.historyClear,
                color: context.colors.bad,
                onTap: state.isClearingHistory
                    ? null
                    : () => bloc.add(const ClearHistoryPressed()),
              ),
            ],
          ),
          const SizedBox(height: AppSpaces.s32),
          if ((state.version, state.buildNumber) case (
            final version?,
            final build?,
          ))
            Text(
              l10n.settingsVersion(version, build),
              style: context.ts.paragraphTiny,
              textAlign: TextAlign.center,
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
