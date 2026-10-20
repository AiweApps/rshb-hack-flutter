import SwiftUI
import SharedLogic

/// «Pick for a dish»: the wines, a dish chosen from what the catalogue lists for them, then
/// the catalogue's answer for every wine.
struct DishPairingView: View {
    @ObservedObject private var observableState: ObservableValue<DishPairingState>
    private let component: DishPairingComponent

    /// «Another dish»: the one the catalogue does not list goes to the assistant as a draft.
    @State private var isCustomDishExpanded = false
    @State private var customDish = ""
    @FocusState private var isCustomDishFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(component: DishPairingComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
    }

    var body: some View {
        let state = observableState.value

        content
            .pairingNavigationTitle(
                title: String(localized: "pairing_title"),
                subtitle: subtitle(state)
            )
            .background(AppTheme.paper.ignoresSafeArea())
            .toastBanner(message: toastMessage(state), onConsumed: component.onToastConsumed)
            .onChange(of: state.selectedDish?.id) { _, selectedDish in
                if selectedDish != nil { closeCustomDish() }
            }
            .sensoryFeedback(trigger: state.toast) { _, toast in
                guard let toast else { return nil }
                return toast == DishPairingToast.saved ? .success : .warning
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

    /// Before a dish: the wines, the dishes and «Another dish». After: the dish, then what
    /// the catalogue says for every wine, with save and «Change dish» at the bottom.
    private func mainContent(state: DishPairingState) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let dish = state.selectedDish {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dish.label)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        caption
                    }
                    PairingResultsView(state: state, dish: dish)
                } else {
                    if !state.wines.isEmpty {
                        wineRoster(state)
                    }
                    dishChoice(state)
                }
            }
            .padding(20)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        // The field is in the sibling bottom bar, so the scroll view's automatic
        // dismissal does not own it. Observe a vertical drag without taking the
        // scroll gesture or taps away from the dish rows.
        .simultaneousGesture(DragGesture(minimumDistance: 12).onChanged { value in
            guard isCustomDishFocused,
                  abs(value.translation.height) > abs(value.translation.width) else { return }
            isCustomDishFocused = false
            Keyboard.dismiss()
        })
        .appBottomControlBar {
            if state.selectedDish != nil {
                PairingBottomBar(
                    state: state,
                    onSave: component.onSaveClicked,
                    onChangeDish: component.onChangeDishClicked,
                    onAddWine: component.onAddWineClicked
                )
            } else if isCustomDishExpanded {
                customDishForm
            }
        }
    }

    private func dishChoice(_ state: DishPairingState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "pairing_heading"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            if state.wines.isEmpty {
                Text(String(localized: "pairing_no_wines"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink2)
                Button(String(localized: "pairing_add_wine"), action: component.onAddWineClicked)
                    .foregroundStyle(AppTheme.onWine)
                    .appPrimaryButtonStyle()
                    .controlSize(.large)
            } else if state.hasNoDishes {
                Text(String(localized: "pairing_no_dishes_title"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink2)
                // «Another dish» below is the main way on; another wine is the quieter one.
                Button(String(localized: "pairing_add_wine"), action: component.onAddWineClicked)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.wine)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
            } else {
                DishChipsRow(
                    dishes: state.dishes,
                    isInteractive: !state.isSaving,
                    onSelect: { component.onDishTapped(dishId: $0.id) }
                )
                if state.isLoadingDishes {
                    loadingDishes
                }
            }
            if !state.wines.isEmpty {
                customDishEntry
                caption
            }
        }
    }

    /// The wines the choice is made among, shown until a dish is chosen.
    private func wineRoster(_ state: DishPairingState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "pairing_wines_title"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.muted)
            PairingWineRoster(
                wines: state.wines,
                referenceAccess: state.referenceAccess,
                onLink: { component.onCardLinkClicked(url: $0) }
            )
        }
    }

    private var customDishEntry: some View {
        Button {
            if isCustomDishExpanded {
                closeCustomDish()
            } else {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                    isCustomDishExpanded = true
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "pairing_other")).font(.body.weight(.medium))
                    Text(String(localized: "pairing_other_hint"))
                        .font(.footnote).foregroundStyle(AppTheme.muted)
                }
                Spacer(minLength: 0)
                AppIcon(systemName: isCustomDishExpanded ? "minus" : "plus")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(AppTheme.wine)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Keep the input and its next action in one native keyboard-aware inset. An
    /// inline field lets UIKit reveal only the caret while hiding Continue below it.
    private var customDishForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(String(localized: "pairing_other"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer(minLength: 0)
                CloseButton(action: closeCustomDish)
                    .frame(minWidth: 44, minHeight: 44)
            }
            TextField(String(localized: "pairing_other_placeholder"), text: $customDish, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(AppTheme.paper2, in: RoundedRectangle(cornerRadius: 12))
                .focused($isCustomDishFocused)
            HStack(spacing: 12) {
                Text(String(localized: "pairing_other_draft_hint"))
                    .font(.caption).foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    let dish = customDish.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !dish.isEmpty else { return }
                    isCustomDishFocused = false
                    Keyboard.dismiss()
                    component.onCustomDishRequested(dish: dish, prompt: String(
                        format: String(localized: "pairing_other_prompt"), dish))
                } label: {
                    Text(String(localized: "pairing_other_continue_short"))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minHeight: 32)
                        .contentShape(Rectangle())
                }
                .controlSize(.regular)
                .foregroundStyle(AppTheme.onWine)
                .appPrimaryButtonStyle()
                .accessibilityLabel(String(localized: "pairing_other_continue"))
                .disabled(customDish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .appMatteCard(cornerRadius: 20)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .transition(.opacity)
        .task {
            // Assign focus only once the conditional bar has mounted. Reopening
            // mounts a new bar and retains the user's text in customDish.
            await Task.yield()
            guard isCustomDishExpanded, !Task.isCancelled else { return }
            isCustomDishFocused = true
        }
    }

    private func closeCustomDish() {
        isCustomDishFocused = false
        Keyboard.dismiss()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            isCustomDishExpanded = false
        }
    }

    /// More dishes may still arrive from the catalogue; the ones in already stay usable.
    private var loadingDishes: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text(String(localized: "pairing_loading_dishes"))
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private var caption: some View {
        Text(String(localized: "pairing_caption"))
            .font(.caption)
            .foregroundStyle(AppTheme.muted)
    }

    /// «Among N wines from the comparison»; none while there are no dishes to choose among.
    private func subtitle(_ state: DishPairingState) -> String? {
        guard state.screenState is ScreenState.Content, !state.hasNoDishes else { return nil }
        return L10n.plural("pairing_among_wines", count: state.wineCount)
    }

    private func toastMessage(_ state: DishPairingState) -> String? {
        guard let toast = state.toast else { return nil }
        return toast == DishPairingToast.saved
            ? String(localized: "pairing_toast_saved")
            : String(localized: "pairing_toast_save_failed")
    }
}
