import 'package:flutter/material.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/language_service.dart';
import '../../../shared/presentation/bottle_mark.dart';

/// The app mark and name while the start-up decision is made.
class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BottleMark(size: AppSize.s96),
          const SizedBox(height: AppSpaces.s24),
          Text(
            context.localization.scanKicker.toUpperCase(),
            style: context.ts.kicker,
          ),
          const SizedBox(height: AppSpaces.s8),
          Text(context.localization.appTitle, style: context.ts.h1),
        ],
      ),
    );
  }
}
