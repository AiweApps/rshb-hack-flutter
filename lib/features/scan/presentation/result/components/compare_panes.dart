import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/remote_image.dart';
import '../../../domain/models/bottle_box.dart';
import 'photo_crop.dart';

/// The bottle from the user's photo next to the catalogue reference, as the
/// top of the best card. Tapping opens the full-screen comparison.
class ComparePanes extends StatelessWidget {
  static const double _paneAspect = 3 / 4;

  final String photoPath;
  final BottleBox? crop;
  final List<int>? frame;
  final String? referenceUrl;
  final Map<String, String> referenceHeaders;
  final VoidCallback onTap;

  const ComparePanes({
    super.key,
    required this.photoPath,
    required this.crop,
    required this.frame,
    required this.referenceUrl,
    required this.referenceHeaders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return InkWell(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppPadding.p14,
          AppPadding.p14,
          AppPadding.p14,
          AppPadding.p0,
        ),
        child: Row(
          children: [
            Expanded(
              child: _Pane(
                caption: l10n.resultYourPhoto,
                child: crop == null
                    ? _Placeholder(text: l10n.resultPhotoMissing)
                    : PhotoCrop(
                        photoPath: photoPath,
                        crop: crop!,
                        frame: frame,
                      ),
              ),
            ),
            const SizedBox(width: AppSpaces.s10),
            Expanded(
              child: _Pane(
                caption: l10n.resultReference,
                child: ReferencePane(
                  url: referenceUrl,
                  headers: referenceHeaders,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The reference image filling its box, or a placeholder when it is missing.
class ReferencePane extends StatelessWidget {
  final String? url;
  final Map<String, String> headers;

  const ReferencePane({super.key, required this.url, required this.headers});

  @override
  Widget build(BuildContext context) {
    // References are served at 480px at most: decoding them whole is cheap,
    // and the pane's box is what bounds the image.
    return SizedBox.expand(
      child: RemoteImage(
        url: url,
        headers: headers,
        fit: BoxFit.contain,
        errorWidget: _Placeholder(
          text: context.localization.resultReferenceMissing,
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final String caption;
  final Widget child;

  const _Pane({required this.caption, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: ComparePanes._paneAspect,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.paper2,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
        const SizedBox(height: AppSpaces.s4),
        Text(
          caption,
          style: context.ts.paragraphTiny,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String text;

  const _Placeholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p8),
        child: Text(
          text,
          style: context.ts.paragraphTiny,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
