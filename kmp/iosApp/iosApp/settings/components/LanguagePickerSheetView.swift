import SwiftUI
import SharedLogic

struct LanguagePickerSheetView: View {
    private let component: LanguagePickerComponent

    init(component: LanguagePickerComponent) {
        self.component = component
    }

    var body: some View {
        OptionPickerSheet(
            title: String(localized: "settings_language"),
            options: component.codes.map { OptionPickerSheet.Option(id: $0, title: LanguageLabel.name(for: $0)) },
            selectedId: component.current,
            onSelect: { component.onSelected(code: $0) },
            onCancel: component.onCancelClicked
        )
    }
}

/// Display name of a language code, in the app's own language.
enum LanguageLabel {
    static func name(for code: String) -> String {
        switch code {
        case "ru": String(localized: "language_russian")
        case "en": String(localized: "language_english")
        default: code
        }
    }
}
