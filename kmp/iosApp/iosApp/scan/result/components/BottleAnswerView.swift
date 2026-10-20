import SwiftUI
import SharedLogic

/// The answer for one bottle: the photo block, the wine, the two actions, what the card says
/// about it, then the similar options.
struct BottleAnswerView: View {
    let view: RecognitionView
    let bottle: RecognizedBottle
    let photoPath: String
    let referenceAccess: ReferenceAccess?
    /// Gastronomy of the best card; `nil` while it loads.
    let facts: WineFacts?
    let isFactsLoading: Bool
    let factsError: AppError?
    let onFactsRetry: () -> Void
    let isBestInCompare: Bool
    let compareCount: Int
    let onOpenCompare: () -> Void
    let onCompare: (WineCard) -> Void
    let onAlternative: (WineCard) -> Void
    let onAddToCompare: () -> Void
    let onRemoveFromCompare: () -> Void
    let onPairDish: () -> Void
    let onLinkTap: (String) -> Void

    @State private var pairDishCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let best = bottle.best {
                bestAnswer(best)
            } else {
                ResultEmptyCard(title: nil, text: String(localized: "result_no_match_for_bottle"))
                    .padding(.horizontal, 16)
            }
            alternatives
        }
    }

    private var showsNumber: Bool {
        view.bottles.count > 1 || view.isExplicitRoi
    }

    private var tag: String {
        let best = String(localized: "result_best_match")
        return showsNumber ? "\(L10n.format("result_bottle_n", bottle.number)) · \(best)" : best
    }

    @ViewBuilder
    private func bestAnswer(_ best: WineCard) -> some View {
        let url = referenceAccess?.resolve(reference: best.reference)
        ComparePanesView(
            photoPath: photoPath,
            crop: view.cropOf(bottle: bottle),
            frame: view.frame,
            referenceUrl: url,
            referenceAccess: referenceAccess,
            onTap: { onCompare(best) }
        )
        .padding(.horizontal, 16)

        BottleTitleBlock(card: best, tag: tag)
            .padding(.horizontal, 16)

        if let verdict = DecisionLabel.text(for: bottle.decisionKind) {
            Text(verdict)
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.warn)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.warn.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 16)
        }

        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { primaryAction; pairDishAction }
                VStack(alignment: .leading, spacing: 10) { primaryAction; pairDishAction }
            }
        }
        .padding(.horizontal, 16)

        BottleFactsView(card: best, facts: facts, isLoading: isFactsLoading,
                        loadError: factsError, onRetry: onFactsRetry, onLinkTap: onLinkTap)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }

    // Once the wine is in the set, opening the comparison replaces adding it.
    @ViewBuilder
    private var primaryAction: some View {
        if isBestInCompare {
            Button(action: onOpenCompare) {
                HStack(spacing: 8) {
                    AppIcon(systemName: "square.split.2x1")
                    Text(String(localized: "result_compare_wines"))
                    Text("\(compareCount)")
                        .monospacedDigit()
                        .padding(.horizontal, 7)
                        .background(AppTheme.onWine.opacity(0.22), in: Capsule())
                        .contentTransition(.numericText())
                }
                .foregroundStyle(AppTheme.onWine)
            }
            .appPrimaryButtonStyle()
            .controlSize(.large)
            .buttonBorderShape(.capsule)
        } else {
            AddToCompareButton(
                isInCompare: false,
                style: .inline,
                onAdd: onAddToCompare,
                onRemove: onRemoveFromCompare
            )
        }
    }

    private var pairDishAction: some View {
        Button {
            pairDishCount += 1
            onPairDish()
        } label: {
            Label(String(localized: "result_pair_dish"), appSymbol: "fork.knife")
        }
        .appSecondaryButtonStyle()
        .tint(AppTheme.wine)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .sensoryFeedback(.impact(weight: .light), trigger: pairDishCount)
    }

    @ViewBuilder
    private var alternatives: some View {
        if !bottle.alternatives.isEmpty {
            Text(String(localized: "result_alternatives"))
                .font(.title3.bold())
                .padding(.horizontal, 16)
                .padding(.top, 8)
            ForEach(bottle.alternatives, id: \.slug) { alternative in
                WineCardView(
                    card: alternative,
                    tag: nil,
                    isBest: false,
                    referenceUrl: referenceAccess?.resolve(reference: alternative.reference),
                    referenceAccess: referenceAccess,
                    onTap: { onAlternative(alternative) },
                    onLinkTap: onLinkTap
                )
                .padding(.horizontal, 16)
            }
        }
    }
}
