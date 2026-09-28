import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/widgets/dialog/confirmation_dialog.dart';
import '../../../core/widgets/dialog/picker_dialog.dart';
import '../../../shared/helpers/service_locator.dart';
import '../../../shared/presentation/service_detail_sheet.dart';
import '../application/bloc/settings_bloc.dart';
import '../application/bloc/settings_state.dart';
import '../application/bloc/settings_uieffect.dart';
import 'components/about_sheet.dart';
import 'components/settings_labels.dart';
import 'settings_content.dart';
import 'settings_error.dart';
import 'settings_loading.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.localization.settingsTitle)),
      body: SafeArea(
        child: BaseBlocPresentationListener<SettingsBloc>(
          listener: _onUiEffect,
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) => switch (state.screenStatus) {
              ScreenStatus.loading => const SettingsLoading(),
              ScreenStatus.content => SettingsContent(state: state),
              ScreenStatus.error => SettingsError(state: state),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onUiEffect(
    BuildContext context,
    BaseBlocUiEffect effect,
  ) async {
    final bloc = context.read<SettingsBloc>();
    final l10n = context.localization;

    switch (effect) {
      case PickTheme(:final current):
        await PickerDialog.show(
          context,
          title: l10n.settingsTheme,
          items: [
            for (final mode in AppThemeMode.values)
              PickerItem(id: mode.name, label: themeModeLabel(context, mode)),
          ],
          selectedItemId: current.name,
          onItemSelected: (id) =>
              bloc.add(ThemeChanged(themeMode: AppThemeMode.values.byName(id))),
        );
      case PickLanguage(:final current, :final languageCodes):
        await PickerDialog.show(
          context,
          title: l10n.settingsLanguage,
          items: [
            for (final code in languageCodes)
              PickerItem(id: code, label: languageLabel(context, code)),
          ],
          selectedItemId: current,
          onItemSelected: (code) =>
              bloc.add(LanguageChanged(languageCode: code)),
        );
      case ShowServiceDetail(:final availability):
        await ServiceDetailSheet.show(context, availability);
      case OpenOnboarding():
        sl<AppRouter>().navigateToOnboarding();
      case ShowAbout():
        await AboutSheet.show(context);
      case OpenExternalUrl(:final url):
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      case ConfirmClearHistory():
        final bool confirmed = await showConfirmationDialog(
          context: context,
          title: l10n.historyClearConfirmTitle,
          message: l10n.historyClearConfirmBody,
          confirmButtonText: l10n.historyClearConfirm,
          cancelButtonText: l10n.commonCancel,
          isDangerous: true,
        );
        if (!context.mounted) return;
        // A cancel is an answer too: nothing to send, the bloc stays idle.
        if (confirmed) bloc.add(const ClearHistoryConfirmed());
    }
  }
}
