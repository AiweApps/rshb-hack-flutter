import SwiftUI
import SharedLogic

/// Text and colour for a `ServiceState`, shared by the scan tab, the settings row and the
/// detail sheet.
enum ServiceStateText {

    static func label(for state: ServiceState) -> String {
        if state.availability == .busy, state.waiting > 0 {
            return L10n.format("status_busy_queue", state.waiting)
        }
        return label(for: state.availability)
    }

    static func label(for availability: ServiceAvailability) -> String {
        L10n.string(labelKey(availability))
    }

    static func detail(for availability: ServiceAvailability) -> String {
        L10n.string(detailKey(availability))
    }

    static func color(for availability: ServiceAvailability) -> Color {
        if availability == .checking {
            return AppTheme.muted
        } else if availability == .ready {
            return AppTheme.ok
        } else if availability == .busy {
            return AppTheme.warn
        } else if availability == .dev {
            return AppTheme.gold
        } else {
            return AppTheme.bad
        }
    }

    private static func labelKey(_ availability: ServiceAvailability) -> String {
        if availability == .checking { return "status_checking" }
        if availability == .ready { return "status_ready" }
        if availability == .busy { return "status_busy" }
        if availability == .down { return "status_down" }
        if availability == .unavailable { return "status_unavailable" }
        if availability == .noAccess { return "status_no_access" }
        if availability == .rateLimited { return "status_rate_limited" }
        if availability == .offline { return "status_offline" }
        return "status_dev"
    }

    private static func detailKey(_ availability: ServiceAvailability) -> String {
        if availability == .checking { return "status_auto_refresh" }
        if availability == .ready { return "status_ready_detail" }
        if availability == .busy { return "status_busy_detail" }
        if availability == .down { return "status_down_detail" }
        if availability == .unavailable { return "status_unavailable_detail" }
        if availability == .noAccess { return "status_no_access_detail" }
        if availability == .rateLimited { return "status_rate_limited_detail" }
        if availability == .offline { return "status_offline_detail" }
        return "status_dev_detail"
    }
}

/// A coloured dot that breathes while the service can take a photo.
struct ServiceStatusDot: View {
    let availability: ServiceAvailability
    @State private var dimmed = false

    var body: some View {
        let pulsing = availability.canRecognize
        Circle()
            .fill(ServiceStateText.color(for: availability))
            .frame(width: 10, height: 10)
            .opacity(pulsing && dimmed ? 0.4 : 1)
            .animation(
                pulsing ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                value: dimmed
            )
            .onChange(of: pulsing, initial: true) { _, isPulsing in
                dimmed = isPulsing
            }
            .accessibilityHidden(true)
    }
}

/// Dot plus label. Tap handling and the background belong to the caller.
struct ServiceStatusLabel: View {
    let state: ServiceState

    var body: some View {
        HStack(spacing: 8) {
            ServiceStatusDot(availability: state.availability)
            Text(ServiceStateText.label(for: state))
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
    }
}
