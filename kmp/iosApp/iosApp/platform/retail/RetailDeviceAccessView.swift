import SwiftUI
import WebKit

struct RetailDeviceSettingsSection: View {
    @EnvironmentObject private var session: PerekrestokDeviceMCP
    var body: some View {
        Section {
            Toggle(String(localized: "retail_device_enabled"), isOn: Binding(
                get: { session.enabled }, set: { session.setEnabled($0) }))
                .disabled(!session.supported)
            if session.supported && session.enabled {
                Button { session.presentSite() } label: {
                    Label(String(localized: "retail_device_open"), appSymbol: "storefront")
                }
            }
        } header: { Text("retail_device_title") }
        footer: { Text(session.supported ? "retail_device_privacy" : "retail_device_simulator") }
    }
}

/// Platform access sheet (like the camera/permission UI), not a second app navigation stack.
struct RetailDeviceAccessView: View {
    @ObservedObject var session: PerekrestokDeviceMCP
    let close: () -> Void
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !session.enabled {
                    ContentUnavailableView {
                        Label(String(localized: "retail_device_disabled"), appSymbol: "storefront", iconSize: 48)
                    } description: { Text("retail_device_privacy") }
                    actions: { Button("retail_device_connect") { session.setEnabled(true); session.openSite() } }
                } else {
                    Text(statusText).font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    RetailDeviceWebView(session: session)
                }
            }
            .navigationTitle(String(localized: "retail_device_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("common_close", action: close) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { session.reloadSite() } label: { AppIcon(systemName: "arrow.clockwise") }
                        .disabled(!session.enabled).accessibilityLabel(String(localized: "retail_device_retry"))
                }
            }
        }
        .tint(AppTheme.wine)
    }
    private var statusText: String {
        switch session.status {
        case .notOpened: String(localized: "retail_device_not_opened")
        case .loading: String(localized: "retail_device_loading")
        case .ready: String(localized: "retail_device_ready")
        case .attention: String(localized: "retail_device_attention")
        case .disabled: String(localized: "retail_device_disabled")
        }
    }
}

private struct RetailDeviceWebView: UIViewRepresentable {
    let session: PerekrestokDeviceMCP
    func makeUIView(context: Context) -> WKWebView { session.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
