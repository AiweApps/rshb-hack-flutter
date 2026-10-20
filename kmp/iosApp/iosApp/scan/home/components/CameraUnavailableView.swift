import SwiftUI
import SharedLogic

/// Shown instead of the viewfinder when the camera is denied or missing: what happened, the
/// gallery as the way forward, the settings action when the permission is the cause, and the
/// recent scans in a panel docked to the bottom.
struct CameraUnavailableView: View {
    let status: CameraStatus
    let recent: [ScanHistoryItem]
    let isBusy: Bool
    let onOpenSettings: () -> Void
    let onPickPhoto: () -> Void
    let onRecentTap: (Int64) -> Void
    let onAllScans: () -> Void

    /// Height of the recent panel, which the hero leaves free under itself.
    @State private var panelContentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let reserved = recent.isEmpty ? 0 : panelContentHeight
            ZStack(alignment: .bottom) {
                hero(height: max(geometry.size.height - reserved, 0))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                if !recent.isEmpty {
                    RecentScansPanel(
                        items: recent,
                        contentHeight: $panelContentHeight,
                        onItemTap: onRecentTap,
                        onAllTap: onAllScans
                    )
                }
            }
        }
        .background(AppTheme.paper.ignoresSafeArea())
    }

    // MARK: Parts

    /// Centred in `height`; taller content (small screens, large text) scrolls instead of
    /// running under the panel.
    private func hero(height: CGFloat) -> some View {
        ScrollView {
            card
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity, minHeight: height)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: height)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppIcon(systemName: isUnavailable ? "camera.metering.unknown" : "camera.viewfinder")
                .font(.largeTitle.weight(.light))
                .foregroundStyle(AppTheme.wine)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.body)
                    .foregroundStyle(AppTheme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Button(action: onPickPhoto) {
                    Label(String(localized: "scan_pick_photo"), appSymbol: "photo.on.rectangle.angled")
                }
                .appPrimaryButtonStyle()
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .disabled(isBusy)

                // Both denied statuses end up in the system settings: iOS never shows its
                // permission prompt a second time, so there is nothing to «allow» in the app.
                if status == CameraStatus.denied || status == CameraStatus.permanentlyDenied {
                    Button(String(localized: "scan_open_settings"), action: onOpenSettings)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.wine)
                        .frame(minHeight: 44)
                        .buttonStyle(.plain)
                        .disabled(isBusy)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Copy

    private var isUnavailable: Bool { status == CameraStatus.unavailable }

    private var title: String {
        String(localized: isUnavailable ? "scan_camera_unavailable_title" : "scan_no_camera_title")
    }

    private var message: String {
        if isUnavailable {
            return String(localized: "scan_camera_unavailable_body")
        }
        return String(localized: status == CameraStatus.denied ? "scan_no_camera_ask_body" : "scan_no_camera_body")
    }
}
