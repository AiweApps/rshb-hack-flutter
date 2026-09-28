import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/presentation/app_icons.dart';
import '../../../../../core/services/language_service.dart';
import '../../../domain/models/recognition_view.dart';
import '../../../domain/models/reference_access.dart';
import '../../../domain/models/wine_card.dart';
import 'compare_panes.dart';
import 'decision_label.dart';
import 'result_empty_card.dart';
import 'wine_card_tile.dart';

/// The answer for one bottle: heading with the verdict, the best card with
/// the comparison on top, then the similar options.
class BottleAnswer extends StatelessWidget {
  final RecognitionView view;
  final RecognizedBottle bottle;
  final String photoPath;
  final ReferenceAccess? referenceAccess;
  final bool showRescanHint;
  final VoidCallback onRescan;
  final VoidCallback onRescanHintDismissed;
  final ValueChanged<WineCard> onCompare;
  final ValueChanged<String> onLinkTap;

  const BottleAnswer({
    super.key,
    required this.view,
    required this.bottle,
    required this.photoPath,
    required this.referenceAccess,
    required this.showRescanHint,
    required this.onRescan,
    required this.onRescanHintDismissed,
    required this.onCompare,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final WineCard? best = bottle.best;
    final String? verdict = decisionLabel(context, bottle.decision);
    final bool canRescan =
        !view.isExplicitRoi &&
        view.bottles.length > 1 &&
        bottle.selectRoi != null;
    final Map<String, String> headers = referenceAccess?.headers ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  view.bottles.length > 1 || view.isExplicitRoi
                      ? l10n.resultBottleN(bottle.number)
                      : l10n.resultAnswerTitle,
                  style: context.ts.h3,
                ),
              ),
              if (canRescan)
                OutlinedButton(
                  onPressed: () {
                    AppHaptics.tap();
                    onRescan();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      AppSize.s0,
                      AppSize.buttonSmallHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.p14,
                    ),
                    textStyle: context.ts.buttonSmall,
                  ),
                  child: Text(l10n.resultRescan),
                ),
            ],
          ),
        ),
        if (verdict != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.p16,
              AppPadding.p6,
              AppPadding.p16,
              AppPadding.p0,
            ),
            child: _Verdict(text: verdict),
          ),
        if (canRescan && showRescanHint)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.p16,
              AppPadding.p8,
              AppPadding.p16,
              AppPadding.p0,
            ),
            child: _HintBubble(
              text: l10n.resultRescanHint,
              onDismiss: onRescanHintDismissed,
            ),
          ),
        const SizedBox(height: AppSpaces.s12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
          child: best == null
              ? ResultEmptyCard(title: null, text: l10n.resultNoMatchForBottle)
              : WineCardTile(
                  card: best,
                  tag: l10n.resultBestMatch,
                  isBest: true,
                  referenceUrl: referenceAccess?.resolve(best.reference),
                  referenceHeaders: headers,
                  header: ComparePanes(
                    photoPath: photoPath,
                    crop: view.cropOf(bottle),
                    frame: view.frame,
                    referenceUrl: referenceAccess?.resolve(best.reference),
                    referenceHeaders: headers,
                    onTap: () => onCompare(best),
                  ),
                  onLinkTap: onLinkTap,
                ),
        ),
        if (bottle.alternatives.isNotEmpty) ...[
          const SizedBox(height: AppSpaces.s20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
            child: Text(l10n.resultAlternatives, style: context.ts.h4),
          ),
          const SizedBox(height: AppSpaces.s10),
          for (final alternative in bottle.alternatives)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppPadding.p16,
                AppPadding.p0,
                AppPadding.p16,
                AppPadding.p10,
              ),
              child: WineCardTile(
                card: alternative,
                tag: null,
                isBest: false,
                referenceUrl: referenceAccess?.resolve(alternative.reference),
                referenceHeaders: headers,
                onTap: () => onCompare(alternative),
                onLinkTap: onLinkTap,
              ),
            ),
        ],
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  final String text;

  const _Verdict({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.p10,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: context.colors.warn.withAlpha(AppAlpha.a20),
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Text(
        text,
        style: context.ts.paragraphTiny.copyWith(color: context.colors.warn),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  final String text;
  final VoidCallback onDismiss;

  const _HintBubble({required this.text, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.p12,
        AppPadding.p8,
        AppPadding.p4,
        AppPadding.p8,
      ),
      decoration: BoxDecoration(
        color: context.colors.ink,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.ts.paragraphTiny.copyWith(
                color: context.colors.paper,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            iconSize: AppSize.s18,
            color: context.colors.paper,
            icon: Icon(AppIcon.close.data),
          ),
        ],
      ),
    );
  }
}
