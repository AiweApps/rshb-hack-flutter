import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/dialog/base_bottom_sheet.dart';
import '../../../application/result/bloc/scan_result_uieffect.dart';
import '../../../domain/models/bottle_box.dart';
import 'photo_stage.dart';

/// «Нарисовать рамку»: the photo to draw on; a drawn frame is at once
/// adjustable, and «Сканировать» hands it back. Resolves to the frame in
/// frame pixels, or null when dismissed.
///
/// The frame being drawn is gesture state of this sheet, like the text in a
/// field: only the final frame reaches the bloc.
class DrawFrameSheet extends StatefulWidget {
  final DrawFrameArgs args;

  const DrawFrameSheet({super.key, required this.args});

  static Future<BottleBox?> show(BuildContext context, DrawFrameArgs args) {
    return showModalBottomSheet<BottleBox>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // The sheet is a drawing surface: a swipe must not dismiss it.
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DrawFrameSheet(args: args),
    );
  }

  @override
  State<DrawFrameSheet> createState() => _DrawFrameSheetState();
}

class _DrawFrameSheetState extends State<DrawFrameSheet> {
  BottleBox? _draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final BottleBox? draft = _draft;

    return BaseBottomSheet(
      title: l10n.resultDrawFrame,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * AppSize.resultSheetMax,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: context.colors.ink,
                child: PhotoStage(
                  photoPath: widget.args.photoPath,
                  frame: widget.args.frame,
                  view: widget.args.view,
                  draft: draft,
                  onDraftChanged: (box) => setState(() => _draft = box),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.p16,
                vertical: AppPadding.p12,
              ),
              child: draft == null
                  ? Text(
                      l10n.frameHint,
                      style: context.ts.paragraphSmall,
                      textAlign: TextAlign.center,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AppHaptics.tap();
                              Navigator.of(context).pop();
                            },
                            child: Text(l10n.commonCancel),
                          ),
                        ),
                        const SizedBox(width: AppSpaces.s10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              AppHaptics.confirm();
                              Navigator.of(context).pop(draft);
                            },
                            child: Text(l10n.frameScan),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
