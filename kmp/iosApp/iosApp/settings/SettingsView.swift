import SwiftUI
import SharedLogic

struct SettingsView: View {
    @ObservedObject private var observableState: ObservableValue<SettingsState>
    @ObservedObject private var modalSlot: ObservableValue<ChildSlot<AnyObject, SettingsComponentModal>>
    private let component: SettingsComponent

    init(component: SettingsComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
        self.modalSlot = ObservableValue(component.modalSlot)
    }

    var body: some View {
        let state = observableState.value
        let modal = modalSlot.value.child?.instance
        let confirm = modal as? SettingsComponentModal.ConfirmClear

        content
            .navigationTitle(String(localized: "settings_title"))
            .background(AppTheme.paper.ignoresSafeArea())
        .appModalSheet(modal: confirm == nil ? modal : nil, onDismiss: component.onModalDismissed) { sheet in
            sheetContent(sheet)
        }
        .toastBanner(message: toastMessage(state), onConsumed: component.onToastConsumed)
        .sensoryFeedback(trigger: state.toast) { _, toast in
            guard let toast else { return nil }
            return toast == SettingsToast.historyCleared ? .success : .warning
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
            mainContent(state: state, confirm: modalSlot.value.child?.instance as? SettingsComponentModal.ConfirmClear)
        }
    }

    private func mainContent(state: SettingsState, confirm: SettingsComponentModal.ConfirmClear?) -> some View {
        List {
            SettingsAppearanceSection(
                themeMode: state.themeMode,
                languageCode: state.languageCode,
                onTheme: { component.onThemeSelected(mode: $0) },
                onLanguage: component.onLanguageClicked
            )
            if let backend = state.scannerBackend, backend.selected == .local, !backend.localAvailable {
                Section {
                    Label(String(localized: "local_model_required"), appSymbol: "arrow.down.circle")
                        .foregroundStyle(.secondary)
                }
            } else {
                SettingsServiceSection(
                    serviceState: state.serviceState,
                    catalogCards: state.catalogCards?.int32Value,
                    onStatus: component.onStatusClicked
                )
            }
            if let backend = state.scannerBackend, backend.canChoose {
                ScannerBackendSection(backend: backend, onSelected: { component.onScannerBackendSelected(backend: $0) },
                    onDownload: component.onDownloadLocalModelClicked, onCancel: component.onCancelLocalModelClicked)
            }
            RetailDeviceSettingsSection()
            SettingsHelpSection(
                onShowOnboarding: component.onShowOnboardingClicked,
                onAbout: component.onAboutClicked,
                onOpenSite: component.onOpenSiteClicked
            )
            SettingsDataSection(
                isClearing: state.isClearingHistory,
                confirm: confirm?.component,
                onClear: component.onClearHistoryClicked,
                onConfirmDismiss: component.onModalDismissed
            )
            Section {} footer: {
                Text(L10n.format("settings_version", state.appVersion, state.appBuild))
                    .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func sheetContent(_ modal: SettingsComponentModal) -> some View {
        if let language = modal as? SettingsComponentModal.LanguagePicker {
            LanguagePickerSheetView(component: language.component)
        } else if let service = modal as? SettingsComponentModal.ServiceDetail {
            ServiceDetailSheetView(component: service.component)
        } else if let about = modal as? SettingsComponentModal.About {
            AboutSheetView(component: about.component)
        }
    }

    private func toastMessage(_ state: SettingsState) -> String? {
        guard let toast = state.toast else { return nil }
        return toast == SettingsToast.historyCleared
            ? String(localized: "history_cleared")
            : String(localized: "history_clear_failed")
    }
}
