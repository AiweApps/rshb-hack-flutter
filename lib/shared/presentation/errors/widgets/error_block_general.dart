import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../error_type.dart';
import 'error_block_content.dart';

/// Inline error card that replaces a failed section. Tapping it retries.
class ErrorBlockGeneral extends StatelessWidget {
  final ErrorType errorType;
  final VoidCallback onRefresh;
  final bool isLoading;
  final bool isTransparent;
  final bool useHorizontalPadding;

  const ErrorBlockGeneral({
    super.key,
    required this.errorType,
    required this.onRefresh,
    this.isLoading = false,
    this.isTransparent = false,
    this.useHorizontalPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onRefresh,
      child: Padding(
        padding: useHorizontalPadding
            ? const EdgeInsets.symmetric(horizontal: AppPadding.p16)
            : EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isTransparent ? Colors.transparent : context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: isTransparent
                ? null
                : Border.all(color: context.colors.rule),
          ),
          padding: const EdgeInsets.only(
            top: AppPadding.p32,
            bottom: AppPadding.p24,
          ),
          child: Center(
            child: ErrorBlockContent(
              errorType: errorType,
              isLoading: isLoading,
            ),
          ),
        ),
      ),
    );
  }
}
