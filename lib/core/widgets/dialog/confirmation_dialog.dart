import 'package:flutter/material.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';

/// Two-button confirm/cancel dialog.
///
/// Prefer the [showConfirmationDialog] helper unless you need to drive
/// [isLoading] yourself.
class ConfirmationDialog extends StatelessWidget {
  final String? title;
  final String message;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  /// Paints the confirm button in the destructive colour.
  final bool isDangerous;

  /// Shows a spinner in the confirm button and blocks dismissal.
  final bool isLoading;

  const ConfirmationDialog({
    super.key,
    this.title,
    required this.message,
    required this.confirmButtonText,
    required this.cancelButtonText,
    required this.onConfirm,
    required this.onCancel,
    this.isDangerous = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Dialog(
        backgroundColor: context.colors.neutrals100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p16,
            vertical: AppPadding.p32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: context.ts.paragraphBold.copyWith(
                    color: context.colors.neutrals900,
                    fontSize: FontSize.s20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppPadding.p12),
              ],
              Text(
                message,
                style: context.ts.paragraphSmall.copyWith(
                  color: context.colors.neutrals900,
                  fontSize: FontSize.s16,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.p32),
              Row(
                children: [
                  Expanded(child: _buildConfirmButton(context)),
                  const SizedBox(width: AppPadding.p12),
                  Expanded(child: _buildCancelButton(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final background = isDangerous
        ? context.colors.delete
        : context.colors.neutrals900;

    return SizedBox(
      height: AppSize.s52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: context.colors.neutrals100,
          disabledBackgroundColor: background.withAlpha(AppAlpha.a30),
          disabledForegroundColor: context.colors.neutrals100.withAlpha(
            AppAlpha.a30,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r10),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: AppSize.s20,
                height: AppSize.s20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colors.neutrals100,
                  ),
                ),
              )
            : Text(
                confirmButtonText,
                style: context.ts.paragraphSmall.copyWith(
                  color: context.colors.neutrals100,
                  fontSize: FontSize.s18,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      height: AppSize.s52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onCancel,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.neutrals400,
          foregroundColor: context.colors.neutrals900,
          disabledBackgroundColor: context.colors.neutrals400.withAlpha(
            AppAlpha.a30,
          ),
          disabledForegroundColor: context.colors.neutrals900.withAlpha(
            AppAlpha.a30,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r10),
          ),
          elevation: 0,
        ),
        child: Text(
          cancelButtonText,
          style: context.ts.paragraphSmall.copyWith(
            color: context.colors.neutrals900,
            fontSize: FontSize.s18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Shows a confirmation dialog and resolves to the user's choice.
///
/// Returns false when dismissed by tapping outside.
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String message,
  required String confirmButtonText,
  required String cancelButtonText,
  String? title,
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => ConfirmationDialog(
      title: title,
      message: message,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      isDangerous: isDangerous,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );

  return result ?? false;
}
