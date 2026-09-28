import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/dialog/base_bottom_sheet.dart';
import '../../../application/result/bloc/scan_result_uieffect.dart';

/// «Ещё»: share the JSON, technical details. Resolves to the pick or null.
class MoreSheet extends StatelessWidget {
  final MoreSheetArgs args;

  const MoreSheet({super.key, required this.args});

  static Future<ResultMoreOption?> show(
    BuildContext context,
    MoreSheetArgs args,
  ) {
    return showModalBottomSheet<ResultMoreOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoreSheet(args: args),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final int? number = args.bottleNumber;

    return BaseBottomSheet(
      title: l10n.resultMore,
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (args.hasAnswer) ...[
            _Option(
              icon: Icons.ios_share,
              label: l10n.resultShareJson,
              onTap: () =>
                  Navigator.of(context).pop(ResultMoreOption.shareFull),
            ),
            if (number != null)
              _Option(
                icon: Icons.ios_share,
                label: args.isRoi
                    ? l10n.resultShareFrameJson
                    : l10n.resultShareBottleJson(number),
                onTap: () =>
                    Navigator.of(context).pop(ResultMoreOption.shareBottle),
              ),
            _Option(
              icon: Icons.code,
              label: l10n.resultTechDetails,
              onTap: () =>
                  Navigator.of(context).pop(ResultMoreOption.techDetails),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(AppPadding.p16),
              child: Text(l10n.loadingNote, style: context.ts.paragraphSmall),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Option({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.colors.wine),
      title: Text(label, style: context.ts.paragraph),
      minTileHeight: AppSize.s56,
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
    );
  }
}
