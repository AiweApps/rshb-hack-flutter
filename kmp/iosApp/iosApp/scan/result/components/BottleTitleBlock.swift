import SwiftUI
import SharedLogic

/// The wine name (30 pt bold), the producer and «Белое сухое · Кубань» under the photo,
/// with a small tag above (which bottle, and that this is the best match) when there is one.
struct BottleTitleBlock: View {
    let card: WineCard
    let tag: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let tag {
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(AppTheme.gold)
            }
            HeroTitle(text: card.presentationTitle)
            if let producer = card.producer, !producer.isEmpty,
               producer.caseInsensitiveCompare(card.presentationTitle) != .orderedSame {
                Text(producer)
                    .font(.title3)
                    .foregroundStyle(AppTheme.ink2)
            }
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        [card.category, card.region]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
