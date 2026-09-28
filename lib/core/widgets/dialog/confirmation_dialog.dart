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
        insetPadding: const EdgeInsets.symmetric(horizontal: AppPadding.p24),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p24,
            vertical: AppPadding.p28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(title!, style: context.ts.h3, textAlign: TextAlign.center),
                const SizedBox(height: AppSpaces.s12),
              ],
              Text(
                message,
                style: context.ts.paragraph,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpaces.s24),
              _ConfirmButton(
                text: confirmButtonText,
                onPressed: isLoading ? null : onConfirm,
                isDangerous: isDangerous,
                isLoading: isLoading,
              ),
              const SizedBox(height: AppSpaces.s8),
              OutlinedButton(
                onPressed: isLoading ? null : onCancel,
                child: Text(cancelButtonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDangerous;
  final bool isLoading;

  const _ConfirmButton({
    required this.text,
    required this.onPressed,
    required this.isDangerous,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = isDangerous
        ? context.colors.bad
        : context.colors.wine;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        disabledBackgroundColor: background.withAlpha(AppAlpha.a40),
      ),
      child: isLoading
          ? SizedBox(
              width: AppSize.s20,
              height: AppSize.s20,
              child: CircularProgressIndicator(color: context.colors.onWine),
            )
          : Text(text),
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
