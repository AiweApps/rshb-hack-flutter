import SwiftUI
import SharedLogic

/// One wine against the dish: thumbnail, name, «producer · category» and either why it
/// fits, that the card lists other dishes, or that the card says nothing.
struct PairingMatchRow: View {
    enum Kind {
        case matched, notListed, noData
    }

    let match: PairingMatch
    let dish: DishLabel
    let kind: Kind
    let referenceAccess: ReferenceAccess?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            WinePhotoView(
                card: match.card,
                photoPath: match.photoPath,
                crop: match.crop,
                frame: match.frame,
                referenceAccess: referenceAccess,
                fit: match.crop != nil
            )
            .frame(width: 40, height: 60)
            .clipped()
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(match.card.presentationTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                }
                // The section header already says matched or not listed; only «no data» needs its reason.
                if kind == .noData {
                    Text(explanation)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            Spacer(minLength: 0)
            if isMatch {
                AppIcon(systemName: "checkmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.ok)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityValue(kind == .noData ? "" : explanation)
    }

    private var isMatch: Bool { kind == .matched }

    private var explanation: String {
        switch kind {
        case .matched: L10n.format("pairing_explanation", dish.label)
        case .notListed: String(localized: "pairing_not_listed")
        case .noData: String(localized: "pairing_no_data_row")
        }
    }

    private var subtitle: String {
        [match.card.producer, match.card.category]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
