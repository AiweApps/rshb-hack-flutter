import SwiftUI
import SharedLogic

/// Source-backed wine with compact actions; full catalogue details stay available on demand.
struct AssistantWineCardView: View {
    @State private var detailsExpanded = false
    let wine: AssistantWine
    let referenceAccess: ReferenceAccess?
    let isSaved: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onFavorite: () -> Void
    let onCompare: () -> Void
    let onLink: (String) -> Void

    var isComparisonContext = false
    var onSourcePhoto: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                if wine.reference != nil || wine.photoPath != nil {
                    artwork
                        .frame(width: 56, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    if wine.uncertain || !isComparisonContext {
                        Text(String(localized: wine.uncertain ? "assistant_wine_uncertain" : "assistant_wine_found"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(wine.uncertain ? AppTheme.warn : AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(wine.title)
                        .font(AppTheme.wineTitle)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let producer = wine.producer, !producer.isEmpty {
                        Text(producer)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    let meta = [wine.category, wine.region].compactMap { $0 }.filter { !$0.isEmpty }
                    if !meta.isEmpty {
                        Text(meta.joined(separator: " · "))
                            .font(.footnote)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !pairings.isEmpty {
                Text(pairings.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(AppTheme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // One light action row, with natural-width labels rather than equal narrow columns.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { selectButton; compareButton; detailsButton; Spacer(minLength: 0); favoriteButton }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 16) { selectButton; compareButton; Spacer(minLength: 0); favoriteButton }
                    detailsButton
                }
                VStack(alignment: .leading, spacing: 0) { selectButton; compareButton; detailsButton; favoriteButton }
            }

            if detailsExpanded {
                if let description = wine.description_, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "assistant_pairs_with"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                    Text(pairings.isEmpty ? String(localized: "common_no_data") : pairings.joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let onSourcePhoto, wine.photoPath != nil {
                    Button(action: onSourcePhoto) {
                        HStack(spacing: 10) {
                            userPhoto
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            Label(String(localized: "assistant_view_photo"), appSymbol: "arrow.up.left.and.arrow.down.right")
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink2)
                }
                if let url = wine.pageUrl, !url.isEmpty {
                    Button { onLink(url) } label: {
                        Label(String(localized: "assistant_open_catalogue"), appSymbol: "arrow.up.right")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, detailsExpanded ? 12 : 6)
        .appMatteCard(cornerRadius: 16)
    }

    private var pairings: [String] {
        wine.foodPairings.isEmpty ? wine.dishes.map(\.name) : wine.foodPairings
    }

    private var favoriteButton: some View {
        Button(action: onFavorite) {
            AppIcon(systemName: isSaved ? "heart.fill" : "heart")
                .font(.body.weight(.regular))
                .foregroundStyle(isSaved ? AppTheme.wine : AppTheme.ink2)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: isSaved ? "assistant_remove_favorite" : "assistant_favorite"))
    }

    private var selectButton: some View {
        Button(action: onSelect) {
            Text(String(localized: "assistant_ios_wine_dinner"))
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.footnote.weight(.medium))
        .foregroundStyle(AppTheme.wine)
        .accessibilityLabel(String(localized: "assistant_ios_wine_dinner"))
    }

    private var compareButton: some View {
        Button(action: onCompare) {
            Text(String(localized: "assistant_ios_compare"))
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(AppTheme.ink2)
        .accessibilityLabel(String(localized: "result_compare_wines"))
    }

    private var detailsButton: some View {
        Button { detailsExpanded.toggle() } label: {
            HStack(spacing: 4) {
                Text(String(localized: detailsExpanded ? "compare_hide_description" : "assistant_v3_wine_details"))
                AppIcon(systemName: detailsExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.regular))
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(AppTheme.ink2)
        .accessibilityValue(String(localized: detailsExpanded ? "compare_hide_description" : "compare_show_description"))
    }

    private var artwork: some View {
        WinePhotoView(reference: wine.reference, photoPath: wine.photoPath,
                      crop: wine.sourceCrop, frame: wine.sourceFrame,
                      referenceAccess: referenceAccess)
    }

    @ViewBuilder
    private var userPhoto: some View {
        if let path = wine.photoPath {
            LocalPhotoView(path: path, maxPixel: 320) {
                ProgressView()
            }
        } else {
            AppIcon(systemName: "wineglass")
                .foregroundStyle(AppTheme.muted)
                .accessibilityHidden(true)
        }
    }
}
