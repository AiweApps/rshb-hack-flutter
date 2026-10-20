import SwiftUI
import SharedLogic

struct ScanResultView: View {
    @ObservedObject private var observableState: ObservableValue<ScanResultState>
    @ObservedObject private var modalSlot: ObservableValue<ChildSlot<AnyObject, ScanResultComponentModal>>
    private let component: ScanResultComponent

    init(component: ScanResultComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
        self.modalSlot = ObservableValue(component.modalSlot)
    }

    var body: some View {
        let state = observableState.value
        let modal = modalSlot.value.child?.instance
        let drawFrame = modal as? ScanResultComponentModal.DrawFrame

        chrome(state: state)
            .toastBanner(message: ResultToastText.message(for: state.toast), onConsumed: component.onToastConsumed)
            .appModalSheet(modal: drawFrame == nil ? modal : nil, onDismiss: component.onModalDismissed) { modal in
                sheetContent(modal)
            }
            // Drawing is a drag; under a sheet the pull-down recognizer would take it.
            .appFullScreenModal(modal: drawFrame, onDismiss: component.onModalDismissed) { draw in
                DrawFrameView(component: draw.component)
            }
            .sensoryFeedback(trigger: state.phase) { _, phase in
                if phase == ResultPhase.answer { return .success }
                if phase == ResultPhase.failed { return .warning }
                return nil
            }
            .sensoryFeedback(trigger: state.toast) { _, toast in
                (toast is ScanResultToast.AddToCompareFailed || toast is ScanResultToast.RemoveFromCompareFailed)
                    ? .warning
                    : nil
            }
    }

    /// The navigation bar and the bottom bar around the content.
    private func chrome(state: ScanResultState) -> some View {
        let hasInlineCompare = state.selectedBottle?.best.map { state.isInCompare(card: $0) } ?? false
        return content
            .safeAreaInset(edge: .bottom, alignment: .leading) {
                // Only an already-added bottle carries the forward action inline.
                // Keep the existing set reachable when another bottle is selected.
                if state.canOpenCompare && !hasInlineCompare {
                    GlassPill(
                        title: String(localized: "result_compare_wines"),
                        systemImage: "square.split.2x1",
                        badge: Int(state.compareCount),
                        action: component.onCompareWinesClicked
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle(String(localized: "result_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { topBar(state: state) }
    }

    @ToolbarContentBuilder
    private func topBar(state: ScanResultState) -> some ToolbarContent {
        if state.hasAnswer {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: component.onMoreClicked) {
                    Label(String(localized: "result_more"), appSymbol: "ellipsis.circle")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let state = observableState.value
        let screenState = state.screenState

        if screenState is ScreenState.Loading {
            LoadingStateView()
        } else if let error = screenState as? ScreenState.Error {
            ErrorStateView(error: error.error, onRetry: component.onRetryClicked)
        } else if screenState is ScreenState.Content {
            mainContent(state: state)
        }
    }

    private func mainContent(state: ScanResultState) -> some View {
        ResultAnswerList(
            state: state,
            onBottleSelected: { component.onBottleSelected(instanceId: $0) },
            onCompare: { component.onCompareCardClicked(instanceId: $0, card: $1) },
            onAlternative: { component.onAlternativeClicked(instanceId: $0, card: $1) },
            onAddToCompare: { component.onAddToCompareClicked(instanceId: $0) },
            onRemoveFromCompare: { component.onRemoveFromCompareClicked(instanceId: $0) },
            onPairDish: { component.onPairDishClicked(instanceId: $0) },
            onOpenCompare: component.onCompareWinesClicked,
            onLinkTap: { component.onCardLinkClicked(url: $0) },
            onRetry: component.onRetryClicked,
            onFactsRetry: component.onFactsRetryClicked,
            onNewScan: component.onNewScanClicked
        )
    }

    @ViewBuilder
    private func sheetContent(_ modal: ScanResultComponentModal) -> some View {
        if let compare = modal as? ScanResultComponentModal.Compare {
            CompareSheetView(component: compare.component)
        } else if let more = modal as? ScanResultComponentModal.More {
            let state = observableState.value
            let bottle = state.selectedBottle
            let canRemove = bottle?.best.map { state.isInCompare(card: $0) } ?? false
            MoreSheetView(component: more.component, onRemoveFromCompare: canRemove ? {
                guard let bottle else { return }
                component.onModalDismissed()
                component.onRemoveFromCompareClicked(instanceId: bottle.instanceId)
            } : nil)
        } else if let tech = modal as? ScanResultComponentModal.TechDetails {
            TechDetailsSheetView(component: tech.component)
        }
    }
}
