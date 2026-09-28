import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/local_photo.dart';
import '../../../../history/domain/models/scan_record.dart';

/// The last few scans as small cards, with a link to the whole history.
class RecentScansStrip extends StatelessWidget {
  final List<ScanHistoryItem> items;
  final ValueChanged<int> onItemTap;
  final VoidCallback onAllTap;

  const RecentScansStrip({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.scanRecentTitle.toUpperCase(),
                style: context.ts.kicker,
              ),
            ),
            TextButton(
              onPressed: () {
                AppHaptics.tap();
                onAllTap();
              },
              child: Text(l10n.scanRecentAll.toUpperCase()),
            ),
          ],
        ),
        const SizedBox(height: AppSpaces.s8),
        SizedBox(
          height: AppSize.s200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpaces.s12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecentScanCard(
                item: item,
                onTap: () {
                  AppHaptics.tap();
                  onItemTap(item.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback onTap;

  const _RecentScanCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Material(
      color: context.colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        side: BorderSide(color: context.colors.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: AppSize.s140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalPhoto(
                path: item.photoPath,
                width: AppSize.s140,
                height: AppSize.s140,
                borderRadius: AppRadius.r0,
              ),
              Padding(
                padding: const EdgeInsets.all(AppPadding.p10),
                child: Text(
                  item.bestTitle ?? l10n.historyNoMatch,
                  style: context.ts.paragraphTiny.copyWith(
                    color: context.colors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
