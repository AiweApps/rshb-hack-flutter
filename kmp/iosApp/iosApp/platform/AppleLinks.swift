import UIKit
import SharedLogic

/// iOS side of `PlatformLinks`: Safari and the app's own page in Settings.
final class AppleLinks: PlatformLinks {
    private let retail: PerekrestokDeviceMCP
    init(retail: PerekrestokDeviceMCP) { self.retail = retail }

    func openUrl(url: String) {
        guard let address = URL(string: url) else { return }
        if address.absoluteString == PerekrestokDeviceMCP.origin || address.absoluteString == PerekrestokDeviceMCP.origin + "/" {
            #if !targetEnvironment(simulator)
            Task { @MainActor [retail] in retail.presentSite() }
            return
            #endif
        }
        UIApplication.shared.open(address)
    }

    func openAppSettings() {
        guard let address = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(address)
    }
}
