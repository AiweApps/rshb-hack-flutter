import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/helpers/app_haptics.dart';
import '../../../../core/presentation/app_icons.dart';
import '../../../../core/services/language_service.dart';

/// Shown when nothing has been scanned yet.
class HistoryEmpty extends StatelessWidget {
  final VoidCallback onScan;

  const HistoryEmpty({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcon.history.data,
              size: AppSize.s64,
              color: context.colors.muted,
            ),
            const SizedBox(height: AppSpaces.s16),
            Text(
              l10n.historyEmptyTitle,
              style: context.ts.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpaces.s8),
            Text(
              l10n.historyEmptyBody,
              style: context.ts.paragraphSmall.copyWith(
                color: context.colors.ink2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpaces.s24),
            ElevatedButton(
              onPressed: () {
                AppHaptics.tap();
                onScan();
              },
              child: Text(l10n.historyEmptyAction),
            ),
          ],
        ),
      ),
    );
  }
}
