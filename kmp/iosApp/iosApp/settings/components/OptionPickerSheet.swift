import SwiftUI

/// A short list of options in a sheet: the chosen one has a check mark, tapping another
/// reports it. Backs both the theme and the language pickers.
struct OptionPickerSheet: View {
    struct Option: Identifiable {
        let id: String
        let title: String
    }

    let title: String
    let options: [Option]
    let selectedId: String
    let onSelect: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List(options) { option in
                Button {
                    onSelect(option.id)
                } label: {
                    HStack {
                        Text(option.title).foregroundStyle(.primary)
                        Spacer()
                        if option.id == selectedId {
                            AppIcon(systemName: "checkmark").foregroundStyle(AppTheme.wine)
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton(isInToolbar: true, action: onCancel)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
