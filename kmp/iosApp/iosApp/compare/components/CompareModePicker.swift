import SwiftUI

/// The «Differences / All» switch under the wine cards.
struct CompareModePicker: View {
    let showAll: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Picker(String(localized: "compare_title"), selection: Binding(
            get: { showAll },
            set: onChange
        )) {
            Text(String(localized: "compare_segment_diff")).tag(false)
            Text(String(localized: "compare_segment_all")).tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .sensoryFeedback(.selection, trigger: showAll)
    }
}
