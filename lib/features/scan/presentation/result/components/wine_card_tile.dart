import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/remote_image.dart';
import '../../../domain/models/wine_card.dart';

/// One catalogue card: reference thumbnail, tag, title, producer, meta line
/// and the link to «Своё вино». Never shows a confidence figure — the
/// service does not calculate one.
class WineCardTile extends StatelessWidget {
  final WineCard card;
  final String? tag;
  final bool isBest;
  final String? referenceUrl;
  final Map<String, String> referenceHeaders;

  /// Replaces the thumbnail (the best card shows the comparison instead).
  final Widget? header;
  final VoidCallback? onTap;
  final ValueChanged<String>? onLinkTap;

  const WineCardTile({
    super.key,
    required this.card,
    required this.tag,
    required this.isBest,
    required this.referenceUrl,
    required this.referenceHeaders,
    this.header,
    this.onTap,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final colors = context.colors;
    final String? url = card.catalogueUrl;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        side: BorderSide(
          color: isBest ? colors.wine : colors.rule,
          width: isBest ? AppSize.s1_5 : AppSize.s1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                AppHaptics.tap();
                onTap!();
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            Padding(
              padding: const EdgeInsets.all(AppPadding.p14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header == null) ...[
                    _ReferenceThumb(
                      url: referenceUrl,
                      headers: referenceHeaders,
                    ),
                    const SizedBox(width: AppSpaces.s12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tag != null && tag!.isNotEmpty) ...[
                          Text(
                            tag!.toUpperCase(),
                            style: context.ts.kicker.copyWith(
                              color: isBest ? colors.wine : colors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpaces.s4),
                        ],
                        Text(
                          card.title,
                          style: isBest ? context.ts.h3 : context.ts.h4,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (card.producer != null &&
                            card.producer!.isNotEmpty) ...[
                          const SizedBox(height: AppSpaces.s4),
                          Text(
                            card.producer!,
                            style: context.ts.paragraphSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (card.metaLine.isNotEmpty) ...[
                          const SizedBox(height: AppSpaces.s4),
                          Text(
                            card.metaLine,
                            style: context.ts.paragraphTiny,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpaces.s8),
                        if (url != null && onLinkTap != null)
                          _LinkButton(
                            label: l10n.resultOpenOnSite,
                            onTap: () => onLinkTap!(url),
                          )
                        else
                          Text(
                            l10n.resultNoSiteUrl,
                            style: context.ts.paragraphTiny,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceThumb extends StatelessWidget {
  final String? url;
  final Map<String, String> headers;

  const _ReferenceThumb({required this.url, required this.headers});

  @override
  Widget build(BuildContext context) {
    return RemoteImage(
      url: url,
      headers: headers,
      width: AppSize.s72,
      height: AppSize.s96,
      borderRadius: AppRadius.r8,
      fit: BoxFit.cover,
      errorWidget: Container(
        width: AppSize.s72,
        height: AppSize.s96,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppPadding.p6),
        decoration: BoxDecoration(
          color: context.colors.paper2,
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Text(
          context.localization.resultReferenceMissing,
          style: context.ts.paragraphTiny,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          AppHaptics.tap();
          onTap();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p8),
        ),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.north_east, size: AppSize.s14),
        label: Text(label.toUpperCase()),
      ),
    );
  }
}
