import SwiftUI
import SharedLogic

/// The body of the result screen for the current phase, and the disclaimer under it.
struct ResultAnswerList: View {
    let state: ScanResultState
    let onBottleSelected: (String?) -> Void
    let onCompare: (String, WineCard) -> Void
    let onAlternative: (String, WineCard) -> Void
    let onAddToCompare: (String) -> Void
    let onRemoveFromCompare: (String) -> Void
    let onPairDish: (String) -> Void
    let onOpenCompare: () -> Void
    let onLinkTap: (String) -> Void
    let onRetry: () -> Void
    let onFactsRetry: () -> Void
    let onNewScan: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                phaseContent
                Text(String(localized: "disclaimer"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
            }
            .padding(.top, 8)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.paper)
    }

    @ViewBuilder
    private var phaseContent: some View {
        if state.phase == ResultPhase.recognizing || state.phase == ResultPhase.waitingRetry {
            ResultLoadingPanel(
                photoPath: state.photoPath,
                geometryProgress: state.geometryProgress,
                isWaitingRetry: state.phase == ResultPhase.waitingRetry,
                isRoiRequest: state.isRoiRequest,
                retryReason: state.retryReason,
                secondsLeft: state.retrySecondsLeft,
                attempt: state.retryAttempt
            )
        } else if state.phase == ResultPhase.failed {
            if let failure = state.failure {
                ResultErrorPanel(failure: failure, onRetry: onRetry, onNewScan: onNewScan)
            }
        } else if state.phase == ResultPhase.answer, let view = state.view {
            answer(view)
        }
    }

    @ViewBuilder
    private func answer(_ view: RecognitionView) -> some View {
        if view.bottles.isEmpty {
            ResultEmptyCard(
                title: DecisionLabel.text(for: view.decisionKind) ?? String(localized: "decision_insufficient"),
                text: emptyText(view.emptyAnswer, isFramed: state.isFramed)
            )
            .padding(.horizontal, 16)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                if view.bottles.count > 1 {
                    BottleChips(
                        view: view,
                        selectedInstanceId: state.selectedInstanceId,
                        winnerInstanceId: state.winnerInstanceId,
                        onSelect: onBottleSelected
                    )
                }
                if let bottle = state.selectedBottle {
                    BottleAnswerView(
                        view: view,
                        bottle: bottle,
                        photoPath: state.photoPath,
                        referenceAccess: state.referenceAccess,
                        facts: bottle.best.flatMap { state.facts[$0.slug] },
                        isFactsLoading: state.isFactsLoading,
                        factsError: bottle.best.flatMap { state.factsErrors[$0.slug] },
                        onFactsRetry: onFactsRetry,
                        isBestInCompare: bottle.best.map { state.isInCompare(card: $0) } ?? false,
                        compareCount: Int(state.compareCount),
                        onOpenCompare: onOpenCompare,
                        onCompare: { onCompare(bottle.instanceId, $0) },
                        onAlternative: { onAlternative(bottle.instanceId, $0) },
                        onAddToCompare: { onAddToCompare(bottle.instanceId) },
                        onRemoveFromCompare: { onRemoveFromCompare(bottle.instanceId) },
                        onPairDish: { onPairDish(bottle.instanceId) },
                        onLinkTap: onLinkTap
                    )
                } else {
                    BottlesOverview(
                        view: view,
                        referenceAccess: state.referenceAccess,
                        isInCompare: { state.isInCompare(card: $0) },
                        onBottleTap: { onBottleSelected($0) },
                        onAddToCompare: onAddToCompare,
                        onRemoveFromCompare: onRemoveFromCompare,
                        onLinkTap: onLinkTap
                    )
                }
            }
        }
    }

    private func emptyText(_ answer: EmptyAnswer, isFramed: Bool) -> String {
        // A framed result has no all-bottles answer to go back to: the advice is to choose
        // the frame again.
        if isFramed { return String(localized: "result_no_bottle_framed") }
        if answer == EmptyAnswer.roiNoTarget { return String(localized: "result_no_bottle_advice_roi") }
        if answer == EmptyAnswer.roi { return String(localized: "result_no_bottle_roi") }
        if answer == EmptyAnswer.autoNoTarget { return String(localized: "result_no_bottle_advice_auto") }
        return String(localized: "result_no_bottle_auto")
    }
}
