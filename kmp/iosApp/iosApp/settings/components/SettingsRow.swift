import SwiftUI

/// A tappable settings row: icon, title, optional current value, optional trailing mark.
struct SettingsRow<Trailing: View>: View {
    let title: String
    let systemImage: String
    var value: String?
    var role: ButtonRole?
    let action: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        Button(role: role, action: action) {
            HStack {
                Label(title, appSymbol: systemImage)
                Spacer(minLength: 8)
                if let value {
                    Text(value).foregroundStyle(.secondary)
                }
                trailing()
            }
            .contentShape(Rectangle())
        }
        .tint(role == nil ? nil : AppTheme.bad)
        .foregroundStyle(role == nil ? Color.primary : AppTheme.bad)
    }
}

/// Trailing mark of a row that opens something.
struct RowChevron: View {
    let systemName: String

    var body: some View {
        AppIcon(systemName: systemName)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
    }
}

extension SettingsRow where Trailing == RowChevron {
    /// A row that drills into a picker: a chevron after the value.
    init(
        title: String,
        systemImage: String,
        value: String? = nil,
        role: ButtonRole? = nil,
        chevron: String = "chevron.right",
        action: @escaping () -> Void
    ) {
        self.init(title: title, systemImage: systemImage, value: value, role: role, action: action) {
            RowChevron(systemName: chevron)
        }
    }
}
