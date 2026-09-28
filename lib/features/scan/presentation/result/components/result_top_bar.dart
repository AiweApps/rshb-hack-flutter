import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';

/// Floating controls over the photo: close, the title, back to all bottles.
class ResultTopBar extends StatelessWidget {
  final bool canGoBackToAll;
  final VoidCallback onClose;
  final VoidCallback onBackToAll;

  const ResultTopBar({
    super.key,
    required this.canGoBackToAll,
    required this.onClose,
    required this.onBackToAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final colors = context.colors;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p12,
          vertical: AppPadding.p8,
        ),
        child: Row(
          children: [
            _RoundButton(
              icon: Icons.arrow_back,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onClose,
            ),
            const SizedBox(width: AppSpaces.s10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.p12,
                vertical: AppPadding.p8,
              ),
              decoration: BoxDecoration(
                color: colors.card.withAlpha(AppAlpha.a85),
                borderRadius: BorderRadius.circular(AppRadius.rPill),
              ),
              child: Text(
                l10n.resultTitle.toUpperCase(),
                style: context.ts.tab.copyWith(color: colors.ink),
              ),
            ),
            const Spacer(),
            if (canGoBackToAll)
              Material(
                color: colors.card.withAlpha(AppAlpha.a85),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    AppHaptics.tap();
                    onBackToAll();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.p12,
                      vertical: AppPadding.p8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.west, size: AppSize.s14, color: colors.wine),
                        const SizedBox(width: AppSpaces.s6),
                        Text(
                          l10n.resultAllBottles.toUpperCase(),
                          style: context.ts.tab.copyWith(color: colors.wine),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.card.withAlpha(AppAlpha.a85),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: () {
          AppHaptics.tap();
          onTap();
        },
        tooltip: tooltip,
        icon: Icon(icon, color: context.colors.ink),
      ),
    );
  }
}
