import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../domain/models/recognition_view.dart';

/// «Все · Бутылка 1 · Бутылка 2 …» — shown when there is more than one.
class BottleChips extends StatelessWidget {
  final RecognitionView view;
  final String? selectedInstanceId;
  final ValueChanged<String?> onSelected;

  const BottleChips({
    super.key,
    required this.view,
    required this.selectedInstanceId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: Row(
        children: [
          _Chip(
            label: l10n.resultTabAll,
            isSelected: selectedInstanceId == null,
            onTap: () => onSelected(null),
          ),
          for (final bottle in view.bottles) ...[
            const SizedBox(width: AppSpaces.s8),
            _Chip(
              label: view.isNearCenter(bottle)
                  ? l10n.resultBottleNearCenterTag(bottle.number)
                  : l10n.resultBottleN(bottle.number),
              isSelected: selectedInstanceId == bottle.instanceId,
              onTap: () => onSelected(bottle.instanceId),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color fg = isSelected ? colors.onWine : colors.ink2;

    // Filled like the web `.chip`: paper on a rule border, wine when chosen.
    return Material(
      color: isSelected ? colors.wine : colors.paper2,
      shape: StadiumBorder(
        side: BorderSide(color: isSelected ? colors.wine : colors.rule),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.select();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p14,
            vertical: AppPadding.p10,
          ),
          child: Text(label, style: context.ts.tab.copyWith(color: fg)),
        ),
      ),
    );
  }
}
