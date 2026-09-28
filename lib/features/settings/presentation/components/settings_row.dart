import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/helpers/app_haptics.dart';

/// One line of a settings card: an icon, a title, an optional second line,
/// and on the right either a value with a chevron or a custom [trailing].
///
/// Knows nothing about the bloc: the tap comes back through [onTap]. With
/// [onTap] null the row is static and shows no chevron.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Second line under the title, e.g. the catalogue size.
  final String? subtitle;

  /// Current value shown before the chevron, e.g. the chosen theme.
  final String? value;

  /// Replaces the value and the chevron, e.g. a status pill.
  final Widget? trailing;

  /// Tint for the icon and the title; the destructive row uses `bad`.
  final Color? color;

  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color foreground = color ?? colors.ink;
    final Color iconColor = color ?? colors.ink2;
    final VoidCallback? onTap = this.onTap;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.tap();
              onTap();
            },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.s56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p16,
            vertical: AppPadding.p12,
          ),
          child: Row(
            children: [
              Icon(icon, size: AppSize.s24, color: iconColor),
              const SizedBox(width: AppSpaces.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.ts.paragraph.copyWith(color: foreground),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpaces.s2),
                      Text(subtitle!, style: context.ts.paragraphTiny),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpaces.s12),
              if (trailing != null)
                trailing!
              else ...[
                if (value != null)
                  Flexible(
                    child: Text(
                      value!,
                      style: context.ts.paragraphSmall.copyWith(
                        color: colors.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpaces.s4),
                  Icon(
                    Icons.chevron_right,
                    size: AppSize.s20,
                    color: colors.muted,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
