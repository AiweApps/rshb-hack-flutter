import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/helpers/app_haptics.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/widgets/local_photo.dart';
import '../../domain/models/scan_record.dart';

/// One stored scan: the photo, the best match and when it was taken.
/// Swiping it to the left deletes it.
class HistoryTile extends StatelessWidget {
  static const double _thumbSize = AppSize.s72;

  final ScanHistoryItem item;

  /// What "today" means for the date line.
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const HistoryTile({
    super.key,
    required this.item,
    required this.now,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final colors = context.colors;

    return Dismissible(
      key: ValueKey<int>(item.id),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) {
        AppHaptics.warn();
        onDismissed();
      },
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          onTap: () {
            AppHaptics.tap();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(AppPadding.p12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(
                color: colors.rule,
                width: AppSize.dividerThickness,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalPhoto(
                  path: item.photoPath,
                  width: _thumbSize,
                  height: _thumbSize,
                ),
                const SizedBox(width: AppSpaces.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.bestTitle ?? l10n.historyNoMatch,
                        style: context.ts.h4,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.bestProducer case final producer?) ...[
                        const SizedBox(height: AppSpaces.s2),
                        Text(
                          producer,
                          style: context.ts.paragraphSmall.copyWith(
                            color: colors.ink2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpaces.s6),
                      _MetaLine(
                        parts: [
                          item.createdAt.relativeDay(l10n, now: now),
                          item.createdAt.shortTime(l10n),
                          l10n.historyBottlesCount(item.bottleCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Short facts separated by dots, wrapping when the row is narrow.
class _MetaLine extends StatelessWidget {
  final List<String> parts;

  const _MetaLine({required this.parts});

  @override
  Widget build(BuildContext context) {
    final style = context.ts.paragraphTiny.copyWith(
      color: context.colors.muted,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpaces.s6,
      runSpacing: AppSpaces.s2,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0) const _MetaDot(),
          Text(parts[i], style: style),
        ],
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.s3,
      height: AppSize.s3,
      decoration: BoxDecoration(
        color: context.colors.muted,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Revealed behind the row as it is swiped away.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p24),
      decoration: BoxDecoration(
        color: context.colors.bad,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Icon(
        Icons.delete_outline,
        color: context.colors.onWine,
        size: AppSize.s28,
        semanticLabel: context.localization.historyDelete,
      ),
    );
  }
}
