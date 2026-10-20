import SwiftUI
import SharedLogic

/// The exact compared/saved wines, including bottle geometry from their real scan.
struct PairingWineRoster: View {
    let wines: [PairingWine]
    let referenceAccess: ReferenceAccess?
    let onLink: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(wines, id: \.card.slug) { wine in
                if let url = wine.card.catalogueUrl {
                    Button { onLink(url) } label: { row(wine, hasLink: true) }
                        .buttonStyle(.plain)
                } else {
                    row(wine, hasLink: false)
                }
                if wine.card.slug != wines.last?.card.slug {
                    Divider().overlay(AppTheme.rule).padding(.leading, 62)
                }
            }
        }
    }

    private func row(_ wine: PairingWine, hasLink: Bool) -> some View {
        HStack(spacing: 14) {
            WinePhotoView(card: wine.card, photoPath: wine.photoPath, crop: wine.crop,
                          frame: wine.frame, referenceAccess: referenceAccess)
                .frame(width: 40, height: 60)
                .clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(wine.card.presentationTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let producer = wine.card.producer, !producer.isEmpty {
                    Text(producer).font(.footnote).foregroundStyle(AppTheme.muted)
                }
            }
            Spacer(minLength: 0)
            if hasLink {
                AppIcon(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .accessibilityLabel(String(localized: "common_open_catalogue"))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
