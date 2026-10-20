import SwiftUI
import SharedLogic

/// The «Comparison» tab: the picked wines side by side, differences first.
struct WineCompareView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var observableState: ObservableValue<WineCompareState>
    @ObservedObject private var modalSlot: ObservableValue<ChildSlot<AnyObject, WineCompareComponentModal>>
    private let component: WineCompareComponent

    init(component: WineCompareComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
        self.modalSlot = ObservableValue(component.modalSlot)
    }

    var body: some View {
        let state = observableState.value

        framed(state)
            .appModalSheet(
                modal: modalSlot.value.child?.instance,
                onDismiss: component.onModalDismissed
            ) { modal in
                if let picker = modal as? WineCompareComponentModal.HistoryPicker {
                    HistoryPickerSheetView(component: picker.component)
                }
            }
            .toastBanner(message: toastMessage(state), onConsumed: component.onToastConsumed)
            .sensoryFeedback(trigger: state.toast) { (_: WineCompareToast?, toast: WineCompareToast?) -> SensoryFeedback? in
                guard let toast else { return nil }
                return toast == WineCompareToast.added ? .success : .warning
            }
            // A wine leaving the set, from the card or from anywhere else.
            .sensoryFeedback(.impact(weight: .light), trigger: state.entries.count) { (old: Int, new: Int) -> Bool in
                new < old
            }
    }

    /// The page with its title, background and the «+» in the bar; split out of `body` so the
    /// type checker handles the modifier chain in reasonable time.
    private func framed(_ state: WineCompareState) -> some View {
        content
            .navigationTitle(String(localized: "compare_title"))
            .background(AppTheme.paper.ignoresSafeArea())
            .toolbar { addToolbarItem(canAdd: canAdd(state)) }
    }

    private func canAdd(_ state: WineCompareState) -> Bool {
        state.screenState is ScreenState.Content && state.canAddMore
    }

    @ToolbarContentBuilder
    private func addToolbarItem(canAdd: Bool) -> some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItem(placement: .topBarTrailing) { addButton(canAdd: canAdd) }
                // The button draws its own wine glass; the bar's shared glass would cover the tint.
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarTrailing) { addButton(canAdd: canAdd) }
        }
    }

    private func addButton(canAdd: Bool) -> some View {
        CompareAddButton(
            isEnabled: canAdd,
            onPickFromHistory: component.onPickFromHistoryClicked,
            onNewScan: component.onScanClicked
        )
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

    @ViewBuilder
    private func mainContent(state: WineCompareState) -> some View {
        if state.entries.isEmpty {
            CompareEmptyView(
                title: String(localized: "compare_empty_title"),
                message: String(localized: "compare_empty_body"),
                onPickFromHistory: component.onPickFromHistoryClicked,
                onScan: component.onScanClicked
            )
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    entryList(state: state)
                    if state.needsSecondWine {
                        needSecondWine
                    } else {
                        table(state: state)
                    }
                    // After the differences: the next step once the reader has compared.
                    CompareActions(
                        canPairDish: state.canPairDish,
                        onPlanDinner: {
                            component.onPlanDinnerClicked(prompt: String(localized: "compare_plan_dinner_prompt"))
                        },
                        onPairDish: component.onPairDishClicked
                    )
                    .padding(.horizontal, 16)
                    Text(String(localized: "compare_footer"))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// The wines one under another, numbered as their table columns.
    private func entryList(state: WineCompareState) -> some View {
        GroupedSection {
            ForEach(Array(state.entries.enumerated()), id: \.element.slug) { index, entry in
                CompareEntryHeader(
                    entry: entry,
                    ordinal: index + 1,
                    referenceAccess: state.referenceAccess,
                    onRemove: { component.onRemoveClicked(slug: entry.slug) },
                    onLink: { component.onCardLinkClicked(url: $0) }
                )
            }
        }
        .padding(.horizontal, 16)
    }

    /// One wine alone: the nudge to add a second.
    private var needSecondWine: some View {
        VStack(spacing: 16) {
            Text(String(localized: "compare_need_second"))
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
            CompareAddActions(
                onPickFromHistory: component.onPickFromHistoryClicked,
                onScan: component.onScanClicked
            )
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func table(state: WineCompareState) -> some View {
        CompareModePicker(
            showAll: state.showAll,
            onChange: { component.onShowAllChanged(showAll: $0) }
        )
        .padding(.horizontal, 16)

        // Three columns fit a phone at ordinary text sizes; accessibility sizes keep the sideways table.
        if state.scrollsSideways && dynamicTypeSize.isAccessibilitySize {
            CompareSidewaysTable(state: state)
        } else {
            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(state.entries.enumerated()), id: \.element.slug) { index, entry in
                        CompareColumnTitle(ordinal: index + 1, title: entry.card.presentationTitle)
                    }
                }
                // Lines up with the cells inside the grouped block.
                .padding(.horizontal, 16)
                rows(state: state)
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func rows(state: WineCompareState) -> some View {
        if state.visibleRows.isEmpty {
            CompareNoDifferencesText()
        } else {
            CompareRowsSection(rows: state.visibleRows, stacksLongRows: state.scrollsSideways)
        }
    }

    private func toastMessage(_ state: WineCompareState) -> String? {
        guard let toast = state.toast else { return nil }
        if toast == WineCompareToast.added { return String(localized: "compare_toast_added") }
        if toast == WineCompareToast.alreadyThere { return String(localized: "compare_toast_already") }
        if toast == WineCompareToast.full { return String(localized: "compare_toast_full") }
        if toast == WineCompareToast.addFailed { return String(localized: "compare_toast_add_failed") }
        return String(localized: "compare_remove_failed")
    }
}
