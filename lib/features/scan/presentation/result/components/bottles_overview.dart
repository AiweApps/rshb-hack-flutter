import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/services/language_service.dart';
import '../../../domain/models/recognition_view.dart';
import '../../../domain/models/reference_access.dart';
import 'result_empty_card.dart';
import 'wine_card_tile.dart';

/// «Все»: one card per bottle, its best match; tapping picks the bottle.
class BottlesOverview extends StatelessWidget {
  final RecognitionView view;
  final ReferenceAccess? referenceAccess;
  final ValueChanged<String> onBottleTap;
  final ValueChanged<String> onLinkTap;

  const BottlesOverview({
    super.key,
    required this.view,
    required this.referenceAccess,
    required this.onBottleTap,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Column(
      children: [
        for (final bottle in view.bottles)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.p16,
              AppPadding.p0,
              AppPadding.p16,
              AppPadding.p10,
            ),
            child: bottle.best == null
                ? GestureDetector(
                    onTap: () => onBottleTap(bottle.instanceId),
                    child: ResultEmptyCard(
                      title: null,
                      text: l10n.resultBottleNoMatch(bottle.number),
                    ),
                  )
                : WineCardTile(
                    card: bottle.best!,
                    tag: view.isNearCenter(bottle)
                        ? l10n.resultBottleNearCenterTag(bottle.number)
                        : l10n.resultBottleN(bottle.number),
                    isBest: false,
                    referenceUrl: referenceAccess?.resolve(
                      bottle.best!.reference,
                    ),
                    referenceHeaders: referenceAccess?.headers ?? const {},
                    onTap: () => onBottleTap(bottle.instanceId),
                    onLinkTap: onLinkTap,
                  ),
          ),
      ],
    );
  }
}
