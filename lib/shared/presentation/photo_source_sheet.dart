import 'package:flutter/material.dart';

import '../../core/constants/app_style_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/helpers/app_haptics.dart';
import '../../core/services/language_service.dart';
import '../../core/services/photo_picker_service.dart';
import '../../core/widgets/dialog/base_bottom_sheet.dart';

/// Camera or gallery. Resolves to the choice, or null when dismissed; the
/// caller sends the choice back to its bloc as an event.
class PhotoSourceSheet extends StatelessWidget {
  const PhotoSourceSheet({super.key});

  static Future<PhotoSource?> show(BuildContext context) {
    return showModalBottomSheet<PhotoSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PhotoSourceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return BaseBottomSheet(
      title: l10n.scanSourceTitle,
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: l10n.scanTakePhoto,
            onTap: () => Navigator.of(context).pop(PhotoSource.camera),
          ),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: l10n.scanPickPhoto,
            onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
