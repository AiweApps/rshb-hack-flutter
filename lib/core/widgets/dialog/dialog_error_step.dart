import 'package:flutter/material.dart';

import '../../presentation/app_icons.dart';
import 'dialog_result_step.dart';

/// Terminal "it failed" step with a retry/close action.
class DialogErrorStep extends StatelessWidget {
  final String title;
  final String? description;
  final String buttonText;
  final VoidCallback onButtonTap;

  const DialogErrorStep({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onButtonTap,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return DialogResultStep(
      icon: SvgIconRes.toastError,
      title: title,
      description: description,
      buttonText: buttonText,
      onButtonTap: onButtonTap,
    );
  }
}
