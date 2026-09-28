import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/presentation/app_icons.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/navigation/nav_bar_height_provider.dart';
import '../../../../history/domain/models/scan_record.dart';
import '../../../domain/models/camera_status.dart';
import 'recent_scans_strip.dart';

/// The scan tab when the viewfinder cannot run: why, the way out, the
/// gallery as an alternative, and the last scans so the screen is not empty.
class CameraUnavailableView extends StatelessWidget {
  final CameraStatus status;
  final List<ScanHistoryItem> recent;
  final bool isPicking;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final VoidCallback onGallery;
  final ValueChanged<int> onRecentTap;
  final VoidCallback onAllRecent;

  const CameraUnavailableView({
    super.key,
    required this.status,
    required this.recent,
    required this.isPicking,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onGallery,
    required this.onRecentTap,
    required this.onAllRecent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final double barHeight = NavBarHeightProvider.maybeOf(context) ?? 0;
    final bool noCamera = status == CameraStatus.unavailable;

    final Widget message = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          noCamera ? AppIcon.cameraOff.data : AppIcon.camera.data,
          size: AppSize.s48,
          color: context.colors.wine,
        ),
        const SizedBox(height: AppSpaces.s16),
        Text(
          noCamera ? l10n.scanCameraUnavailableTitle : l10n.scanNoCameraTitle,
          style: context.ts.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpaces.s8),
        Text(
          noCamera ? l10n.scanCameraUnavailableBody : l10n.scanNoCameraBody,
          style: context.ts.paragraphSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpaces.s24),
        if (status == CameraStatus.denied)
          ElevatedButton(
            onPressed: () {
              AppHaptics.tap();
              onAllow();
            },
            child: Text(l10n.scanAllowCamera),
          ),
        if (status == CameraStatus.permanentlyDenied)
          ElevatedButton(
            onPressed: () {
              AppHaptics.tap();
              onOpenSettings();
            },
            child: Text(l10n.scanOpenSettings),
          ),
        if (!noCamera) const SizedBox(height: AppSpaces.s8),
        if (noCamera)
          ElevatedButton.icon(
            onPressed: isPicking
                ? null
                : () {
                    AppHaptics.tap();
                    onGallery();
                  },
            icon: Icon(AppIcon.gallery.data, size: AppSize.s20),
            label: Text(l10n.scanPickPhoto),
          )
        else
          TextButton(
            onPressed: isPicking
                ? null
                : () {
                    AppHaptics.tap();
                    onGallery();
                  },
            child: Text(l10n.scanPickPhoto),
          ),
      ],
    );

    // The message sits in the middle of the free space and scrolls only when
    // it does not fit; the recent scans stay pinned above the tab bar.
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.p24,
                vertical: AppPadding.p16,
              ),
              child: message,
            ),
          ),
        ),
        if (recent.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppPadding.p24,
              AppPadding.p0,
              AppPadding.p24,
              barHeight + AppPadding.p16,
            ),
            child: RecentScansStrip(
              items: recent,
              onItemTap: onRecentTap,
              onAllTap: onAllRecent,
            ),
          ),
      ],
    );
  }
}
