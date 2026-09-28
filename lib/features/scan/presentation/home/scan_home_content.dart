import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/helpers/app_haptics.dart';
import '../../../../core/services/language_service.dart';
import '../../../../shared/presentation/service_status_pill.dart';
import '../../application/home/bloc/scan_home_bloc.dart';
import '../../application/home/bloc/scan_home_state.dart';
import 'components/recent_scans_strip.dart';
import 'components/scan_hero.dart';

class ScanHomeContent extends StatelessWidget {
  final ScanHomeState state;

  const ScanHomeContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final bloc = context.read<ScanHomeBloc>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.p20,
        AppPadding.p12,
        AppPadding.p20,
        AppPadding.p24,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.scanKicker.toUpperCase(), style: context.ts.kicker),
                  const SizedBox(height: AppSpaces.s2),
                  Text(l10n.scanTitle, style: context.ts.h2),
                ],
              ),
            ),
            const SizedBox(width: AppSpaces.s12),
            Flexible(
              child: ServiceStatusPill(
                state: state.serviceState,
                onTap: () => bloc.add(const StatusTapped()),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpaces.s24),
        ScanHero(
          isBusy: state.isPicking,
          onTakePhoto: () {
            AppHaptics.tap();
            bloc.add(const TakePhotoPressed());
          },
          onPickPhoto: () {
            AppHaptics.tap();
            bloc.add(const PickPhotoPressed());
          },
        ),
        if (state.recent.isNotEmpty) ...[
          const SizedBox(height: AppSpaces.s32),
          RecentScansStrip(
            items: state.recent,
            onItemTap: (id) => bloc.add(RecentScanTapped(scanId: id)),
            onAllTap: () => bloc.add(const AllScansPressed()),
          ),
        ],
        const SizedBox(height: AppSpaces.s32),
        Text(
          l10n.disclaimer,
          style: context.ts.paragraphTiny,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
