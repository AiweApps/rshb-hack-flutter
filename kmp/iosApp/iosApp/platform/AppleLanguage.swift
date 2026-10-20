import UIKit
import SharedLogic

/// iOS side of `PlatformLanguage`.
///
/// iOS does not let an app switch its own locale at runtime; the per-app language lives on
/// the app's page in Settings, which the system offers because the bundle ships more than
/// one localization. So the selectable list is empty and the row sends the user there.
final class AppleLanguage: PlatformLanguage {

    func currentLanguage() -> String {
        let preferred = Bundle.main.preferredLocalizations.first ?? Self.defaultLanguage
        return Self.supported.contains(preferred) ? preferred : Self.defaultLanguage
    }

    func selectableLanguages() -> [String] { [] }

    func setLanguage(code: String) {
        // Never reached: the system owns the choice on iOS.
    }

    func openLanguageSettings() {
        guard let address = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(address)
    }

    private static let defaultLanguage = "ru"
    private static let supported = ["ru", "en"]
}
