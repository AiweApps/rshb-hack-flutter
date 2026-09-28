import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_style_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/helpers/app_haptics.dart';
import '../../core/services/language_service.dart';
import '../domain/service_availability.dart';

/// The status of the recognition service as a small pill with a coloured
/// dot, the same as on the web. Tapping it is left to the caller.
class ServiceStatusPill extends StatelessWidget {
  final ServiceState state;
  final VoidCallback onTap;

  const ServiceStatusPill({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = serviceStatusColor(context, state.availability);
    final String label = serviceStatusLabel(context, state);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: context.colors.card,
        shape: StadiumBorder(side: BorderSide(color: context.colors.rule)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            AppHaptics.tap();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.p12,
              vertical: AppPadding.p8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: color, pulsing: state.availability.canRecognize),
                const SizedBox(width: AppSpaces.s8),
                Flexible(
                  child: Text(
                    label,
                    style: context.ts.tab.copyWith(color: context.colors.ink2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color serviceStatusColor(BuildContext context, ServiceAvailability kind) {
  final colors = context.colors;
  return switch (kind) {
    ServiceAvailability.checking => colors.muted,
    ServiceAvailability.ready => colors.ok,
    ServiceAvailability.busy => colors.warn,
    ServiceAvailability.dev => colors.gold,
    ServiceAvailability.down ||
    ServiceAvailability.unavailable ||
    ServiceAvailability.noAccess ||
    ServiceAvailability.rateLimited ||
    ServiceAvailability.offline => colors.bad,
  };
}

String serviceStatusLabel(BuildContext context, ServiceState state) {
  final l10n = context.localization;
  return switch (state.availability) {
    ServiceAvailability.checking => l10n.statusChecking,
    ServiceAvailability.ready => l10n.statusReady,
    ServiceAvailability.busy =>
      state.waiting > 0 ? l10n.statusBusyQueue(state.waiting) : l10n.statusBusy,
    ServiceAvailability.down => l10n.statusDown,
    ServiceAvailability.unavailable => l10n.statusUnavailable,
    ServiceAvailability.noAccess => l10n.statusNoAccess,
    ServiceAvailability.rateLimited => l10n.statusRateLimited,
    ServiceAvailability.offline => l10n.statusOffline,
    ServiceAvailability.dev => l10n.statusDev,
  };
}

String serviceStatusDetail(BuildContext context, ServiceAvailability kind) {
  final l10n = context.localization;
  return switch (kind) {
    ServiceAvailability.checking => l10n.statusAutoRefresh,
    ServiceAvailability.ready => l10n.statusReadyDetail,
    ServiceAvailability.busy => l10n.statusBusyDetail,
    ServiceAvailability.down => l10n.statusDownDetail,
    ServiceAvailability.unavailable => l10n.statusUnavailableDetail,
    ServiceAvailability.noAccess => l10n.statusNoAccessDetail,
    ServiceAvailability.rateLimited => l10n.statusRateLimitedDetail,
    ServiceAvailability.offline => l10n.statusOfflineDetail,
    ServiceAvailability.dev => l10n.statusDevDetail,
  };
}

/// The dot "breathes" while the service can take a photo.
class _Dot extends StatefulWidget {
  final Color color;
  final bool pulsing;

  const _Dot({required this.color, required this.pulsing});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  static const double _minOpacity = 0.4;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DurationConstant.d900ms,
      lowerBound: _minOpacity,
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant _Dot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsing != widget.pulsing) _sync();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: AppSize.s10,
        height: AppSize.s10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    if (widget.pulsing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }
}
