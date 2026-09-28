import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/helpers/app_haptics.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/widgets/dialog/base_bottom_sheet.dart';

/// "About the scanner": what it does, the disclaimer, and a button to close.
///
/// Shown only from the page's `_onUiEffect` through [show].
class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      // Above the tab shell, so the floating bar does not overlap it.
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AboutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return BaseBottomSheet(
      title: l10n.settingsAbout,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settingsAboutBody, style: context.ts.paragraph),
            const SizedBox(height: AppSpaces.s12),
            Text(l10n.disclaimer, style: context.ts.paragraphTiny),
            const SizedBox(height: AppSpaces.s24),
            ElevatedButton(
              onPressed: () {
                AppHaptics.tap();
                Navigator.of(context).pop();
              },
              child: Text(l10n.commonGotIt),
            ),
          ],
        ),
      ),
    );
  }
}
