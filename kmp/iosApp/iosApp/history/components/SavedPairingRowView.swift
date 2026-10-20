import SwiftUI
import SharedLogic

/// A kept dish choice: the dish as the title, the wines that matched, and the date.
struct SavedPairingRowView: View {
    let pairing: SavedPairing
    /// The dish named in the app's language, from `HistoryState.dishLabelOf(pairing:)`.
    let dishLabel: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                AppIcon(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(AppTheme.wine)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.wine.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(dishLabel)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text(pairing.wines.map(\.title).joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink2)
                        .lineLimit(2)
                    Text(Date(timeIntervalSince1970: Double(pairing.createdAtMillis) / 1000)
                        .formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer(minLength: 0)
                AppIcon(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
