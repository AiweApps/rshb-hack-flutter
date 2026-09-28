import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/language_service.dart';
import '../error_type.dart';
import 'error_block_content.dart';

/// Whole-page error state with an explicit retry button.
class ErrorFullScreen extends StatelessWidget {
  final ErrorType errorType;
  final VoidCallback onRefresh;
  final bool isLoading;

  const ErrorFullScreen({
    super.key,
    required this.errorType,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBlockContent(
              errorType: errorType,
              isLoading: isLoading,
              horizontalPadding: AppPadding.p16,
              useFullScreenTitle: true,
            ),
            const SizedBox(height: AppSize.s32),
            GestureDetector(
              onTap: isLoading ? null : onRefresh,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.p32,
                  vertical: AppPadding.p16,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary300,
                  borderRadius: BorderRadius.circular(AppRadius.rPill),
                ),
                child: isLoading
                    ? SizedBox(
                        width: AppSize.s14,
                        height: AppSize.s14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.neutrals900,
                        ),
                      )
                    : Text(
                        context.localization.errorReloadButton,
                        style: context.ts.paragraphSmall.copyWith(
                          color: context.colors.neutrals900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
