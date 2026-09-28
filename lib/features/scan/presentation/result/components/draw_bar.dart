import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';

/// The bar at the bottom while a frame is being drawn: the hint and cancel.
class DrawBar extends StatelessWidget {
  final bool hasDraft;
  final VoidCallback onCancel;

  const DrawBar({super.key, required this.hasDraft, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppPadding.p16,
            AppPadding.p8,
            AppPadding.p8,
            AppPadding.p8,
          ),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: context.colors.rule),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasDraft ? l10n.frameRecognize : l10n.frameHint,
                  style: context.ts.paragraphSmall.copyWith(
                    color: context.colors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpaces.s8),
              TextButton(
                onPressed: () {
                  AppHaptics.tap();
                  onCancel();
                },
                child: Text(l10n.commonCancel.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
