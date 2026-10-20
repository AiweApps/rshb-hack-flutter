import SwiftUI
import SharedLogic

/// «All»: one card per bottle with its best match; tapping picks the bottle.
struct BottlesOverview: View {
    let view: RecognitionView
    let referenceAccess: ReferenceAccess?
    let isInCompare: (WineCard) -> Bool
    let onBottleTap: (String) -> Void
    let onAddToCompare: (String) -> Void
    let onRemoveFromCompare: (String) -> Void
    let onLinkTap: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(view.bottles, id: \.instanceId) { bottle in
                if let best = bottle.best {
                    WineCardView(
                        card: best,
                        tag: view.isNearCenter(bottle: bottle)
                            ? L10n.format("result_bottle_near_center_tag", bottle.number)
                            : L10n.format("result_bottle_n", bottle.number),
                        isBest: false,
                        referenceUrl: referenceAccess?.resolve(reference: best.reference),
                        referenceAccess: referenceAccess,
                        onTap: { onBottleTap(bottle.instanceId) },
                        onLinkTap: onLinkTap,
                        compare: WineCardCompare(
                            isInCompare: isInCompare(best),
                            onAdd: { onAddToCompare(bottle.instanceId) },
                            onRemove: { onRemoveFromCompare(bottle.instanceId) }
                        )
                    )
                } else {
                    Button {
                        onBottleTap(bottle.instanceId)
                    } label: {
                        ResultEmptyCard(
                            title: nil,
                            text: L10n.format("result_bottle_no_match", bottle.number)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
