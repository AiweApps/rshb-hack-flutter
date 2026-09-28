import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/presentation/app_icons.dart';
import '../../../../../core/services/language_service.dart';

/// The bar under the answer: compare with the reference, draw a frame,
/// a new scan. Each is an icon over a short caption, like a system toolbar.
class ResultToolbar extends StatelessWidget {
  final bool canCompare;
  final bool canDraw;
  final VoidCallback onCompare;
  final VoidCallback onDraw;
  final VoidCallback onNewScan;

  const ResultToolbar({
    super.key,
    required this.canCompare,
    required this.canDraw,
    required this.onCompare,
    required this.onDraw,
    required this.onNewScan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.card,
        border: Border(top: BorderSide(color: context.colors.rule)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p8,
            vertical: AppPadding.p4,
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToolButton(
                  icon: AppIcon.compare.data,
                  label: l10n.resultCompare,
                  onTap: canCompare ? onCompare : null,
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: AppIcon.frame.data,
                  label: l10n.resultFrame,
                  onTap: canDraw ? onDraw : null,
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: AppIcon.camera.data,
                  label: l10n.resultNewScan,
                  isPrimary: true,
                  onTap: onNewScan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final VoidCallback? onTap = this.onTap;
    final Color color = onTap == null
        ? colors.muted
        : isPrimary
        ? colors.wine
        : colors.ink;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.tap();
              onTap();
            },
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.s56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppPadding.p6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSize.s24, color: color),
              const SizedBox(height: AppSpaces.s4),
              Text(
                label,
                style: context.ts.tab.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
