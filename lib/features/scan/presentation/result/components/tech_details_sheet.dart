import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/widgets/dialog/base_bottom_sheet.dart';
import '../../../domain/models/tech_row.dart';

/// «Технические детали»: the raw fields of the answer, for whoever reviews
/// the recognition. The rows arrive ready from the bloc.
class TechDetailsSheet extends StatelessWidget {
  final List<TechRow> rows;

  const TechDetailsSheet({super.key, required this.rows});

  static Future<void> show(BuildContext context, List<TechRow> rows) {
    return showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TechDetailsSheet(rows: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      title: context.localization.resultTechDetails,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16,
          vertical: AppPadding.p12,
        ),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final row = rows[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppPadding.p8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: context.ts.paragraphTiny),
                const SizedBox(height: AppSpaces.s2),
                SelectableText(row.value, style: context.ts.mono),
              ],
            ),
          );
        },
      ),
    );
  }
}
