import 'package:flutter/material.dart';

import '../../presentation/app_icons.dart';
import 'dialog_result_step.dart';

/// Terminal "it worked" step, meant to be passed as the child of a `BaseDialog`
/// once a multi-step flow completes.
class DialogSuccessStep extends StatelessWidget {
  final String title;
  final String? description;
  final String buttonText;
  final VoidCallback onButtonTap;
  final bool hideButton;

  const DialogSuccessStep({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onButtonTap,
    this.description,
    this.hideButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return DialogResultStep(
      icon: SvgIconRes.toastSuccess,
      title: title,
      description: description,
      buttonText: buttonText,
      onButtonTap: onButtonTap,
      hideButton: hideButton,
    );
  }
}
