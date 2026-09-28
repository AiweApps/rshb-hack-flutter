import 'package:flutter/material.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/presentation/app_icons.dart';
import '../../../core/services/language_service.dart';

/// The same picture the native launch screen shows — the logo centred, the
/// name at the bottom — so the hand-over from native to Flutter is not seen.
/// Sizes and offsets mirror ios/Runner/Base.lproj/LaunchScreen.storyboard.
class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  static const double _logoSize = AppSize.s120;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.paper,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.rLaunchLogo),
                child: PngIconRes.appLogo.widget(
                  width: _logoSize,
                  height: _logoSize,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppPadding.p16,
                  AppPadding.p0,
                  AppPadding.p16,
                  AppPadding.p24,
                ),
                child: Text(
                  context.localization.splashTitle,
                  style: context.ts.h4,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
