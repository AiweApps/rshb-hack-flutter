import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../shared/presentation/bottle_art.dart';

/// The landing card: illustration, promise, the two ways to get a photo.
class ScanHero extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickPhoto;

  const ScanHero({
    super.key,
    required this.isBusy,
    required this.onTakePhoto,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.p20,
        AppPadding.p24,
        AppPadding.p20,
        AppPadding.p20,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.r24),
        border: Border.all(color: context.colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BottleArt(height: AppSize.s160)),
          const SizedBox(height: AppSpaces.s20),
          Text(
            l10n.onboardingKicker.toUpperCase(),
            style: context.ts.kicker.copyWith(color: context.colors.gold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpaces.s8),
          Text(
            l10n.scanHeroTitle,
            style: context.ts.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpaces.s12),
          Text(
            l10n.scanLede,
            style: context.ts.paragraphSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpaces.s24),
          ElevatedButton.icon(
            onPressed: isBusy ? null : onTakePhoto,
            icon: const Icon(Icons.photo_camera_outlined, size: AppSize.s20),
            label: Text(l10n.scanTakePhoto.toUpperCase()),
          ),
          const SizedBox(height: AppSpaces.s10),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onPickPhoto,
            icon: const Icon(Icons.photo_library_outlined, size: AppSize.s20),
            label: Text(l10n.scanPickPhoto.toUpperCase()),
          ),
          const SizedBox(height: AppSpaces.s16),
          Text(
            l10n.scanNote,
            style: context.ts.paragraphTiny,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
