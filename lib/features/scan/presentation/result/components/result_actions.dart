import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';

/// The actions under the answer: draw a frame on its own row (the longest
/// label in either language), then new photo and more.
class ResultActions extends StatelessWidget {
  final VoidCallback onDrawFrame;
  final VoidCallback onNewPhoto;
  final VoidCallback onMore;

  const ResultActions({
    super.key,
    required this.onDrawFrame,
    required this.onNewPhoto,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              AppHaptics.tap();
              onDrawFrame();
            },
            icon: const Icon(Icons.crop_free, size: AppSize.s18),
            label: Text(l10n.resultDrawFrame.toUpperCase()),
          ),
          const SizedBox(height: AppSpaces.s8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.tap();
                    onNewPhoto();
                  },
                  icon: const Icon(
                    Icons.photo_camera_outlined,
                    size: AppSize.s18,
                  ),
                  label: Text(
                    l10n.resultNewPhoto.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpaces.s8),
              OutlinedButton(
                onPressed: () {
                  AppHaptics.tap();
                  onMore();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.p14,
                  ),
                ),
                child: Tooltip(
                  message: l10n.resultMore,
                  child: const Icon(Icons.more_horiz, size: AppSize.s20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
