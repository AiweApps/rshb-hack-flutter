import SwiftUI
import SharedLogic

/// One scan in the history: thumbnail, best match, producer and bottle count, which open the
/// scan; and, for a scan that found a wine, a heart for «My wines» and the compare toggle.
struct HistoryRowView: View {
    let item: ScanHistoryItem
    let isPendingDelete: Bool
    let isFavorite: Bool
    let isInCompare: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onCompare: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    LocalPhotoView(path: item.photoPath, maxPixel: 200) {
                        Rectangle().fill(AppTheme.paper2)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.presentationTitle ?? String(localized: "history_no_match"))
                            .font(.headline)
                            .foregroundStyle(item.bestTitle == nil ? .secondary : .primary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        if let producer = item.bestProducer, !producer.isEmpty,
                           producer.caseInsensitiveCompare(item.presentationTitle ?? "") != .orderedSame {
                            Text(producer)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Text(L10n.plural("history_bottles_count", count: item.bottleCount))
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    Spacer(minLength: 0)
                }
                // The whole row opens the scan, empty space included; only the buttons do not.
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if item.bestSlug != nil {
                favoriteButton
                compareButton
            }
        }
        .opacity(isPendingDelete ? 0.4 : 1)
        .disabled(isPendingDelete)
    }

    private var favoriteButton: some View {
        Button(action: onFavorite) {
            AppIcon(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.body.weight(.regular))
                .foregroundStyle(isFavorite ? AppTheme.wine : AppTheme.ink2)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isFavorite)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFavorite)
        .accessibilityLabel(String(localized: isFavorite ? "assistant_remove_favorite" : "assistant_favorite"))
    }

    private var compareButton: some View {
        Button(action: onCompare) {
            // The compare tab's own glyph, so the button reads as «comparison», not as a generic add.
            AppIcon(systemName: isInCompare ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle")
                .font(.body.weight(.regular))
                .foregroundStyle(isInCompare ? AppTheme.wine : AppTheme.ink2)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isInCompare)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isInCompare)
        .accessibilityLabel(String(localized: isInCompare ? "history_in_compare" : "result_add_to_compare"))
        .accessibilityHint(isInCompare ? String(localized: "history_remove_from_compare_hint") : "")
    }
}
