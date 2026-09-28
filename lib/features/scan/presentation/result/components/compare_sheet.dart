import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/dialog/base_bottom_sheet.dart';
import '../../../application/result/bloc/scan_result_uieffect.dart';
import 'compare_pager.dart';

/// «Сравните с эталоном» as a sheet: the bottle from the photo and the
/// catalogue reference, one swipe apart. Shown from `_onUiEffect`.
class CompareSheet extends StatelessWidget {
  final CompareArgs args;

  const CompareSheet({super.key, required this.args});

  static Future<void> show(BuildContext context, CompareArgs args) {
    return showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompareSheet(args: args),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      title: context.localization.resultCompareTitle,
      padding: const EdgeInsets.only(top: AppPadding.p12),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * AppSize.resultSheetMax,
        child: ComparePager(
          photoPath: args.photoPath,
          crop: args.crop,
          frame: args.frame,
          bottleNumber: args.bottleNumber,
          cardTitle: args.cardTitle,
          referenceUrl: args.referenceUrl,
          referenceHeaders: args.referenceHeaders,
        ),
      ),
    );
  }
}
