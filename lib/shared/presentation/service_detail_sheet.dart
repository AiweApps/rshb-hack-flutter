import 'package:flutter/material.dart';

import '../../core/constants/app_style_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/language_service.dart';
import '../../core/widgets/dialog/base_bottom_sheet.dart';
import '../domain/service_availability.dart';
import 'service_status_pill.dart';

/// What the status pill means, in a sentence. Shown from `_onUiEffect`.
class ServiceDetailSheet extends StatelessWidget {
  final ServiceAvailability availability;

  const ServiceDetailSheet({super.key, required this.availability});

  static Future<void> show(
    BuildContext context,
    ServiceAvailability availability,
  ) {
    return showModalBottomSheet<void>(
      // Above the tab shell, so the floating bar does not overlap it.
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceDetailSheet(availability: availability),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final ServiceState state = ServiceState(availability: availability);

    return BaseBottomSheet(
      title: l10n.settingsService,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSize.s12,
                height: AppSize.s12,
                decoration: BoxDecoration(
                  color: serviceStatusColor(context, availability),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpaces.s10),
              Expanded(
                child: Text(
                  serviceStatusLabel(context, state),
                  style: context.ts.h4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpaces.s12),
          Text(
            serviceStatusDetail(context, availability),
            style: context.ts.paragraph,
          ),
          const SizedBox(height: AppSpaces.s8),
          Text(l10n.statusAutoRefresh, style: context.ts.paragraphTiny),
          const SizedBox(height: AppSpaces.s24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonGotIt),
          ),
        ],
      ),
    );
  }
}
