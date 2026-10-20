import SwiftUI
import SharedLogic

/// One catalogue wine in full, opened from a suggestion for a bottle on the user's photo.
/// The original card is available immediately; catalogue facts enrich it beside the photo.
struct WineDetailView: View {
    @ObservedObject private var observableState: ObservableValue<WineDetailState>
    @ObservedObject private var modalSlot: ObservableValue<ChildSlot<AnyObject, WineDetailComponentModal>>
    private let component: WineDetailComponent

    @State private var compareWithPhotoCount = 0
    @State private var compareTapCount = 0

    init(component: WineDetailComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
        self.modalSlot = ObservableValue(component.modalSlot)
    }

    var body: some View {
        let state = observableState.value
        let modal = modalSlot.value.child?.instance

        content
            .navigationTitle(String(localized: "wine_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toastBanner(message: WineDetailToastText.message(for: state.toast), onConsumed: component.onToastConsumed)
            .appModalSheet(modal: modal, onDismiss: component.onModalDismissed) { modal in
                sheetContent(modal)
            }
            .sensoryFeedback(trigger: state.toast) { _, toast in
                (toast is WineDetailToast.AddToCompareFailed || toast is WineDetailToast.RemoveFromCompareFailed)
                    ? .warning
                    : nil
            }
    }

    @ViewBuilder
    private var content: some View {
        let state = observableState.value
        let screenState = state.screenState

        if screenState is ScreenState.Loading {
            LoadingStateView()
        } else if let error = screenState as? ScreenState.Error {
            ErrorStateView(error: error.error, onRetry: nil)
        } else if screenState is ScreenState.Content {
            mainContent(state: state)
        }
    }

    private func mainContent(state: WineDetailState) -> some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                identity(state: state)
                    .padding(.horizontal, 16)

                actions(state: state)
                    .padding(.horizontal, 16)

                BottleFactsView(
                    card: state.card,
                    facts: state.facts,
                    isLoading: state.isFactsLoading,
                    loadError: state.factsError,
                    onRetry: component.onFactsRetryClicked,
                    onLinkTap: component.onCatalogueLinkClicked
                )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Text(String(localized: "disclaimer"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
            .padding(.top, 8)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.paper)
    }

    private func identity(state: WineDetailState) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 20) {
                WineReferencePhotoView(url: state.referenceUrl, access: state.referenceAccess, height: 190)
                    .frame(width: 112)
                identityText(state.card)
                    .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 16) {
                WineReferencePhotoView(url: state.referenceUrl, access: state.referenceAccess, height: 200)
                identityText(state.card)
            }
        }
    }

    private func identityText(_ card: WineCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.presentationTitle)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let producer = card.producer, !producer.isEmpty,
               producer.caseInsensitiveCompare(card.presentationTitle) != .orderedSame {
                Text(producer)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink2)
            }
            let subtitle = [card.category, card.region].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }

    @ViewBuilder
    private func actions(state: WineDetailState) -> some View {
        let showsCompareWithPhoto = state.canCompareWithPhoto
        let showsAdd = state.canAddToCompare || state.isInCompare
        if showsCompareWithPhoto || showsAdd {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    actionButtons(state: state)
                }
                VStack(alignment: .leading, spacing: 10) {
                    actionButtons(state: state)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func actionButtons(state: WineDetailState) -> some View {
        if state.canCompareWithPhoto {
            Button {
                compareWithPhotoCount += 1
                component.onCompareWithPhotoClicked()
            } label: {
                Label(String(localized: "wine_check_photo_short"), appSymbol: "square.split.2x1")
                    .font(.subheadline.weight(.medium))
                    .fixedSize()
                    .frame(minHeight: 32)
            }
            .appSecondaryButtonStyle()
            .foregroundStyle(AppTheme.ink2)
            .controlSize(.regular)
            .buttonBorderShape(.capsule)
            .accessibilityLabel(String(localized: "wine_compare_with_photo"))
            .sensoryFeedback(.impact(weight: .light), trigger: compareWithPhotoCount)
        }
        if state.canAddToCompare || state.isInCompare {
            Button {
                compareTapCount += 1
                if state.isInCompare {
                    component.onRemoveFromCompareClicked()
                } else {
                    component.onAddToCompareClicked()
                }
            } label: {
                Label(String(localized: state.isInCompare ? "wine_remove_compare_short" : "wine_add_compare_short"),
                      appSymbol: state.isInCompare ? "checkmark" : "plus")
                    .font(.subheadline.weight(.semibold))
                    .fixedSize()
                    .frame(minHeight: 32)
            }
            .appSecondaryButtonStyle()
            .tint(AppTheme.wine)
            .foregroundStyle(AppTheme.wine)
            .controlSize(.regular)
            .buttonBorderShape(.capsule)
            .accessibilityLabel(String(localized: state.isInCompare ? "result_remove_from_compare" : "result_add_to_compare"))
            .sensoryFeedback(.impact(weight: .light), trigger: compareTapCount)
        }
    }

    @ViewBuilder
    private func sheetContent(_ modal: WineDetailComponentModal) -> some View {
        if let compare = modal as? WineDetailComponentModal.Compare {
            CompareSheetView(component: compare.component)
        }
    }
}
