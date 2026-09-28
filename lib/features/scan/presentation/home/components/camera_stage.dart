import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/presentation/app_icons.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/navigation/nav_bar_height_provider.dart';

/// The viewfinder with the shutter, the gallery and the flash over it.
class CameraStage extends StatelessWidget {
  /// Null for a frame or two between «ready» and the controller landing.
  final ValueListenable<CameraController?> preview;
  final bool isFlashOn;
  final bool isCapturing;
  final bool isPicking;
  final VoidCallback onShutter;
  final VoidCallback onGallery;
  final VoidCallback onFlash;

  const CameraStage({
    super.key,
    required this.preview,
    required this.isFlashOn,
    required this.isCapturing,
    required this.isPicking,
    required this.onShutter,
    required this.onGallery,
    required this.onFlash,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final colors = context.colors;
    final double barHeight = NavBarHeightProvider.maybeOf(context) ?? 0;
    final bool busy = isCapturing || isPicking;

    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<CameraController?>(
          valueListenable: preview,
          builder: (context, controller, _) => controller == null
              ? ColoredBox(color: colors.scrim)
              : _Viewfinder(controller: controller),
        ),
        Positioned(
          left: AppPadding.p16,
          right: AppPadding.p16,
          bottom: barHeight + AppPadding.p24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.scanHint,
                style: context.ts.paragraphSmall.copyWith(
                  color: colors.onPhoto,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpaces.s20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundControl(
                    icon: AppIcon.gallery.data,
                    label: l10n.scanPickPhoto,
                    onTap: busy ? null : onGallery,
                  ),
                  _Shutter(onTap: busy ? null : onShutter, busy: isCapturing),
                  _RoundControl(
                    icon: isFlashOn
                        ? AppIcon.flashOn.data
                        : AppIcon.flashOff.data,
                    label: l10n.scanFlash,
                    isActive: isFlashOn,
                    onTap: busy ? null : onFlash,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The preview at its own aspect ratio, cropped to fill the screen.
class _Viewfinder extends StatelessWidget {
  final CameraController controller;

  const _Viewfinder({required this.controller});

  @override
  Widget build(BuildContext context) {
    // The camera reports the size in sensor (landscape) orientation.
    final Size? size = controller.value.previewSize;

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size?.height ?? AppSize.s1,
        height: size?.width ?? AppSize.s1,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  static const double _size = AppSize.s72;
  static const double _ring = AppSize.s4;

  final VoidCallback? onTap;
  final bool busy;

  const _Shutter({required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: context.localization.scanShutter,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                AppHaptics.confirm();
                onTap!();
              },
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.onPhoto, width: _ring),
          ),
          padding: const EdgeInsets.all(AppPadding.p4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null
                  ? colors.onPhoto.withAlpha(AppAlpha.a50)
                  : colors.onPhoto,
            ),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(AppPadding.p16),
                    child: CircularProgressIndicator(color: colors.wine),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: isActive ? colors.gold : colors.scrim.withAlpha(AppAlpha.a40),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap == null
            ? null
            : () {
                AppHaptics.tap();
                onTap!();
              },
        tooltip: label,
        iconSize: AppSize.s24,
        color: colors.onPhoto,
        disabledColor: colors.onPhoto.withAlpha(AppAlpha.a50),
        constraints: const BoxConstraints.tightFor(
          width: AppSize.s52,
          height: AppSize.s52,
        ),
        icon: Icon(icon),
      ),
    );
  }
}
