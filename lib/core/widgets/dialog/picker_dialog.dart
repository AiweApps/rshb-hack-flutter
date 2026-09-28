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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.neutrals100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppPadding.p16),
        constraints: const BoxConstraints(maxHeight: AppSize.s400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppPadding.p12),
            Text(
              title,
              style: context.ts.fieldsetLabel.copyWith(
                fontSize: FontSize.s16,
                color: context.colors.neutrals900,
              ),
            ),
            const SizedBox(height: AppPadding.p16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedItemId == item.id;

                  return ListTile(
                    tileColor: Colors.transparent,
                    title: Text(
                      item.label,
                      style: context.ts.paragraphSmall.copyWith(
                        color: isSelected
                            ? context.colors.neutrals900
                            : context.colors.neutrals600,
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
