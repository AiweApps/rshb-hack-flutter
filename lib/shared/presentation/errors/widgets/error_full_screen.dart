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
              horizontalPadding: AppPadding.p24,
              useFullScreenTitle: true,
            ),
            const SizedBox(height: AppSpaces.s32),
            ElevatedButton(
              onPressed: isLoading ? null : onRefresh,
              child: isLoading
                  ? SizedBox(
                      width: AppSize.s16,
                      height: AppSize.s16,
                      child: CircularProgressIndicator(
                        color: context.colors.onWine,
                      ),
                    )
                  : Text(context.localization.errorReloadButton),
            ),
          ],
        ),
      ),
    );
  }
}
