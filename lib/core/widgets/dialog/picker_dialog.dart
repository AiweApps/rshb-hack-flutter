import 'package:flutter/material.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';

/// Simple single-choice list dialog. Pops itself once an item is picked.
class PickerDialog extends StatelessWidget {
  final String title;
  final List<PickerItem> items;
  final String? selectedItemId;
  final ValueChanged<String> onItemSelected;

  const PickerDialog({
    super.key,
    required this.title,
    required this.items,
    this.selectedItemId,
    required this.onItemSelected,
  });

  /// Shows the picker; [onItemSelected] fires before it closes itself.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<PickerItem> items,
    String? selectedItemId,
    required ValueChanged<String> onItemSelected,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PickerDialog(
        title: title,
        items: items,
        selectedItemId: selectedItemId,
        onItemSelected: onItemSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppPadding.p16),
        constraints: const BoxConstraints(maxHeight: AppSize.s400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpaces.s8),
            Text(title, style: context.ts.h4),
            const SizedBox(height: AppSpaces.s16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedItemId == item.id;

                  return ListTile(
                    title: Text(
                      item.label,
                      style: context.ts.paragraph.copyWith(
                        color: isSelected
                            ? context.colors.wine
                            : context.colors.ink,
                      ),
                    ),
                    onTap: () {
                      onItemSelected(item.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickerItem {
  final String id;
  final String label;

  const PickerItem({required this.id, required this.label});
}
