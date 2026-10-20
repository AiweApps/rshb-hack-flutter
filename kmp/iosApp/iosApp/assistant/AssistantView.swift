import SwiftUI
import PhotosUI
import SharedLogic

/// Native conversation surface. The shared component owns every message and request state;
/// SwiftUI owns only transient picker, focus and disclosure state.
struct AssistantView: View {
    @Environment(\.locale) private var locale
    @EnvironmentObject private var deviceMCP: PerekrestokDeviceMCP
    @ObservedObject private var observableState: ObservableValue<AssistantState>
    @StateObject private var locationRequester = AssistantLocationRequester()
    @StateObject private var speechInput = AssistantSpeechInput()
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var pickerConversationId: String?
    @State private var isPreparingPhotos = false
    @State private var photoImportNotice: PhotoImportNotice?
    @State private var isPickerShown = false
    @State private var isAccountShown = false
    @State private var accountUsername = ""
    @State private var accountPassword = ""
    @State private var registerAccount = false
    @State private var isDrawerShown = false
    @State private var isAddressEntryShown = false
    @State private var addressDraft = ""
    @State private var selectedPhoto: AssistantPhoto?
    @State private var viewerPhotos: [AssistantPhoto] = []
    @State private var viewerIndex = 0
    @State private var chatLayout = ChatLayout()
    @State private var followsTail = true
    @State private var isUserScrolling = false
    @State private var tailRequestTicket = 0
    private enum PhotoImportNotice: Equatable { case failed, limit }
    private struct ChatTailRequest: Equatable {
        let conversationId: String?
        let messageId: String?
        let ticket: Int
        let error: AssistantUiError?
        let phase: AssistantPhase
    }
    private struct ChatLayout: Equatable {
        var conversationId: String? = nil
        var contentHeight: CGFloat = 0
        var viewportHeight: CGFloat = 0
        var visibleBottom: CGFloat = 0
        var overflows: Bool { viewportHeight > 0 && contentHeight > viewportHeight + 1 }
        var isAtEnd: Bool { !overflows || contentHeight - visibleBottom <= 44 }
    }
    @FocusState private var isComposerFocused: Bool
    @FocusState private var isAddressFocused: Bool
    private let component: AssistantComponent
    private let onOpenScanHistory: () -> Void
    private let onOpenSettings: () -> Void

    init(component: AssistantComponent, onOpenScanHistory: @escaping () -> Void = {}, onOpenSettings: @escaping () -> Void = {}) {
        self.onOpenScanHistory = onOpenScanHistory
        self.onOpenSettings = onOpenSettings
        self.component = component
        self.observableState = ObservableValue(component.state)
    }

    var body: some View {
        let state = observableState.value
        content(state)
            .toastBanner(message: noticeText(state), onConsumed: consumeNotice)
            .accessibilityHidden(selectedPhoto != nil || isDrawerShown)
            .navigationTitle(String(localized: "assistant_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                navigationControls
            }
            .background(AppTheme.paper.ignoresSafeArea())
            .toolbarVisibility(.visible, for: .navigationBar)
            .toolbarVisibility(!isComposerFocused && !isAddressFocused ? .visible : .hidden, for: .tabBar)
            // Publish the menu to RootView, above both native navigation containers.
            .preference(
                key: AssistantDrawerOverlayKey.self,
                value: isDrawerShown ? AnyView(drawer(state)) : nil
            )
            // However the menu opens, the keyboard must not stay up over it.
            .onChange(of: isDrawerShown) { _, shown in
                if shown { dropKeyboard() }
            }
            .fullScreenCover(isPresented: Binding(
                get: { selectedPhoto != nil },
                set: { if !$0 { selectedPhoto = nil } }
            )) {
                if let selectedPhoto {
                    AssistantPhotoViewer(
                        photo: selectedPhoto,
                        index: viewerIndex,
                        count: viewerPhotos.count,
                        onPrevious: { moveViewer(by: -1) },
                        onNext: { moveViewer(by: 1) },
                        onClose: { self.selectedPhoto = nil }
                    )
                        .statusBarHidden()
                }
            }
            .sheet(isPresented: $isAccountShown) { accountSheet(state) }
            .onChange(of: state.accountRequestTicket) { _, ticket in if ticket > 0 { isAccountShown = true } }
            .onChange(of: state.accountError) { _, failed in
                if failed && state.account == nil { isAccountShown = true }
            }
            .photosPicker(isPresented: $isPickerShown, selection: $pickerItems,
                          maxSelectionCount: max(1, remainingPhotoCapacity(state)), matching: .images)
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                guard let conversationId = pickerConversationId else { pickerItems = []; return }
                isPreparingPhotos = true
                photoImportNotice = nil
                Task { await attachPickedPhotos(items, conversationId: conversationId) }
            }
            .onChange(of: state.locationRequestTicket) { _, ticket in
                guard ticket > 0 else { return }
                locationRequester.request { latitude, longitude, address in
                    component.onLocationResolved(latitude: latitude, longitude: longitude, address: address)
                }
            }
            .onChange(of: state.conversationId) { _, _ in
                speechInput.cancel(discardTranscript: false)
                closeAddressEntry()
                followsTail = true
                isUserScrolling = false
                photoImportNotice = nil
            }
            .onDisappear {
                speechInput.cancel(discardTranscript: false)
                isDrawerShown = false
            }
    }

    private func drawer(_ state: AssistantState) -> some View {
        AssistantDrawerView(
            state: state,
            onClose: closeDrawer,
            onNewConversation: {
                dropKeyboard()
                component.onNewConversationClicked()
                closeDrawer()
            },
            onConversationSelect: { id in
                component.onConversationSelected(id: id)
                closeDrawer()
            },
            onWineSelect: { wine in
                component.onWineInstanceSelected(
                    photoId: wine.photoId, instanceId: wine.instanceId, slug: wine.slug
                )
                closeDrawer()
            },
            onStoreSelect: { store in
                followLatestResponse()
                component.onStoreSelected(storeId: store.id)
                closeDrawer()
            },
            onUseLocation: {
                closeDrawer()
                component.onLocationRequested()
            },
            onEnterAddress: {
                closeDrawer()
                openAddressEntry()
            },
            onOpenScanHistory: {
                closeDrawer()
                onOpenScanHistory()
            },
            onOpenSettings: {
                closeDrawer()
                onOpenSettings()
            }
        )
    }

    @ToolbarContentBuilder
    private var navigationControls: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(String(localized: "assistant_title"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dropKeyboard()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    isDrawerShown = true
                }
            } label: {
                Image("navigation_menu")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(AppTheme.ink)
            }
            .accessibilityLabel(String(localized: "assistant_menu"))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dropKeyboard()
                component.onNewConversationClicked()
            } label: {
                AppIcon(systemName: "square.and.pencil")
                    .font(.body.weight(.regular))
                    .foregroundStyle(AppTheme.ink)
            }
            .accessibilityLabel(String(localized: "assistant_new_conversation"))
        }
    }

    @ViewBuilder
    private func content(_ state: AssistantState) -> some View {
        if state.screenState is ScreenState.Loading {
            LoadingStateView()
        } else if let error = state.screenState as? ScreenState.Error {
            ErrorStateView(error: error.error, onRetry: component.onRetryClicked)
        } else if state.screenState is ScreenState.Content {
            conversation(state)
        }
    }

    private func conversation(_ state: AssistantState) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: hasConversationRows(state) ? 16 : 0) {
                    if !hasConversationRows(state) {
                        emptyConversation
                            .frame(minHeight: max(0, chatLayout.viewportHeight - 32))
                    } else {
                        ForEach(state.messages, id: \.id) { message in
                            if message.kind == AssistantMessageKind.locationRequest ||
                                message.kind == AssistantMessageKind.storeCandidates ||
                                message.kind == AssistantMessageKind.storeSelected {
                                storeChatItem(message, state)
                            } else {
                            AssistantMessageView(
                                message: message,
                                referenceAccess: state.referenceAccess,
                                selectedWineIdentity: state.selectedWine?.presentationIdentity,
                                savedWineIdentities: Set(state.savedWines.map(\.presentationIdentity)),
                                selectedDinnerOptionId: state.messages.reversed().first(where: {
                                    $0.selectedDinnerOptionId != nil
                                })?.selectedDinnerOptionId,
                                canSelectDinner: state.phase == AssistantPhase.idle,
                                onWineSelect: { wine in
                                    followLatestResponse()
                                    component.onWineDinnerRequested(
                                        photoId: wine.photoId, instanceId: wine.instanceId, slug: wine.slug,
                                        prompt: String(localized: "assistant_wine_dinner_prompt")
                                    )
                                },
                                onWineFavorite: { wine in
                                    component.onWineInstanceFavoriteClicked(
                                        photoId: wine.photoId, instanceId: wine.instanceId, slug: wine.slug
                                    )
                                },
                                onWineCompare: { wine in
                                    component.onWineInstanceCompareClicked(
                                        photoId: wine.photoId, instanceId: wine.instanceId, slug: wine.slug
                                    )
                                },
                                onDinnerSelect: {
                                    followLatestResponse()
                                    component.onDinnerSelected(id: $0)
                                },
                                onReplacementRequest: { id, product in
                                    followLatestResponse()
                                    component.onProductReplacementRequestedFrom(messageId: id, productId: product)
                                },
                                onReplacementCandidateSelect: { id, original, product in
                                    followLatestResponse()
                                    component.onReplacementCandidateChosen(messageId: id, originalProductId: original, productId: product)
                                },
                                onRetry: {
                                    followLatestResponse()
                                    component.onMessageRetryClicked(messageId: message.id)
                                },
                                onLink: { component.onLinkClicked(url: $0) },
                                onPhotoTap: { photo, photos in openViewer(photo, in: photos) },
                                canRetryMessage: state.phase == AssistantPhase.idle && state.retryableMessageIds.contains(message.id),
                                canUseProducts: state.phase == AssistantPhase.idle &&
                                    (message.id == state.activeBasketMessageId || message.id == state.activeReplacementMessageId),
                                onOpenRetailSite: deviceMCP.supported ? { deviceMCP.presentSite() } : nil,
                                foldsText: hasStructuredBasket(for: message, in: state)
                            )
                            .id(message.id)
                            }
                        }
                    }
                    if state.phase != AssistantPhase.idle {
                        HStack(spacing: 10) {
                            ProgressView().tint(AppTheme.wine)
                            Text(phaseText(state.phase))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.ink2)
                        }
                        .padding(.horizontal, 4)
                    }
                    if let errorCode = state.errorCode {
                        inlineError(errorCode)
                    }
                    Color.clear.frame(height: 1).id("assistant-chat-bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            // Short conversations align with the top; only overflowing content can scroll to its tail.
            .defaultScrollAnchor(.top, for: .alignment)
            // The keyboard leaves with a drag down the chat, as in Messages, and with a tap on the
            // chat itself; the tap is simultaneous so buttons and cards in the messages still work.
            .scrollDismissesKeyboard(.interactively)
            // The whole chat area takes the tap, the empty chat included.
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { dropKeyboard() })
            .onScrollPhaseChange { _, phase in
                let wasUserScrolling = isUserScrolling
                isUserScrolling = phase == .interacting || phase == .decelerating
                if (isUserScrolling || (wasUserScrolling && phase == .idle)),
                   chatLayout.conversationId == observableState.value.conversationId {
                    followsTail = chatLayout.isAtEnd
                }
            }
            .onScrollGeometryChange(for: ChatLayout.self) { geometry in
                return ChatLayout(
                    conversationId: state.conversationId,
                    contentHeight: geometry.contentSize.height,
                    // containerSize already excludes the safe-area regions occupied by system bars/composer.
                    viewportHeight: geometry.containerSize.height,
                    visibleBottom: geometry.visibleRect.maxY
                )
            } action: { old, new in
                guard new.conversationId == observableState.value.conversationId else { return }
                chatLayout = new
                // Only a user's scroll changes follow intent. New rows must not be mistaken
                // for a reader moving away from the end, or pull a reader out of history.
                if isUserScrolling { followsTail = new.isAtEnd }
                if followsTail && !isUserScrolling && new.overflows &&
                    (old.contentHeight != new.contentHeight || old.viewportHeight != new.viewportHeight) {
                    proxy.scrollTo("assistant-chat-bottom", anchor: .bottom)
                }
            }
            .appBottomControlBar {
                composer(state)
            }
            .onChange(of: isComposerFocused) { _, focused in
                if focused {
                    followLatestResponse()
                    scrollToTailIfNeeded(proxy)
                }
            }
            .task(id: ChatTailRequest(conversationId: state.conversationId, messageId: state.messages.last?.id,
                                     ticket: tailRequestTicket, error: state.errorCode, phase: state.phase)) {
                guard hasConversationRows(state) else { return }
                // Let the lazy stack publish its real size; cancelled old-chat tasks must not scroll a new chat.
                do { try await Task.sleep(for: .milliseconds(50)) }
                catch { return }
                guard !Task.isCancelled,
                      observableState.value.conversationId == state.conversationId,
                      observableState.value.messages.last?.id == state.messages.last?.id else { return }
                if followsTail && !isUserScrolling { scrollToTailIfNeeded(proxy) }
            }
        }
    }

    /// Clears the focus and asks UIKit too: the focus binding alone does not always reach
    /// the composer in the bottom bar (see `Keyboard`).
    private func dropKeyboard() {
        isComposerFocused = false
        isAddressFocused = false
        Keyboard.dismiss()
    }

    /// An error or pending request replaces the empty welcome scene, even before the first message.
    private func hasConversationRows(_ state: AssistantState) -> Bool {
        !state.messages.isEmpty || state.phase != AssistantPhase.idle || state.errorCode != nil
    }

    private func scrollToTailIfNeeded(_ proxy: ScrollViewProxy) {
        guard chatLayout.conversationId == observableState.value.conversationId,
              chatLayout.overflows else { return }
        proxy.scrollTo("assistant-chat-bottom", anchor: .bottom)
    }

    /// An explicit request follows its progress and reply until the reader scrolls away.
    private func followLatestResponse() {
        followsTail = true
        isUserScrolling = false
        tailRequestTicket += 1
    }

    private func sendMessage() {
        followLatestResponse()
        component.onSendClicked()
    }

    private func hasStructuredBasket(for message: AssistantMessage, in state: AssistantState) -> Bool {
        guard message.kind == AssistantMessageKind.assistantText else { return false }
        return state.messages.contains { item in
            item.kind == AssistantMessageKind.products && item.sourceMessageId == message.id &&
                item.replacementForProductId == nil
        }
    }

    private func remainingPhotoCapacity(_ state: AssistantState) -> Int {
        max(0, 10 - state.attachments.count - Int(state.pendingAttachments))
    }

    private func noticeText(_ state: AssistantState) -> String? {
        if let photoImportNotice {
            return String(localized: photoImportNotice == .failed ? "scan_error_photo_open" : "assistant_photo_limit")
        }
        guard let notice = state.compareNotice else { return nil }
        return String(localized: notice == AssistantCompareNotice.sourceUnavailable
                      ? "assistant_compare_source_unavailable" : "notice_compare_failed")
    }

    private func consumeNotice() {
        if photoImportNotice != nil { photoImportNotice = nil }
        else { component.onCompareNoticeConsumed() }
    }

    private func inlineError(_ errorCode: AssistantUiError) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(assistantErrorMessage(errorCode), appSymbol: "exclamationmark.circle")
                .font(.footnote)
                .foregroundStyle(AppTheme.bad)
                .fixedSize(horizontal: false, vertical: true)
            if errorCode != AssistantUiError.dinnerSelectionStale {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { retailRecoveryAction(errorCode); retryAction(errorCode) }
                        .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: 0) { retailRecoveryAction(errorCode); retryAction(errorCode) }
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.medium))
            }
        }
        .padding(12)
        .appMatteCard(cornerRadius: 16)
    }

    @ViewBuilder
    private func retailRecoveryAction(_ errorCode: AssistantUiError) -> some View {
        if errorCode == AssistantUiError.retailAccessRequired && deviceMCP.supported {
            Button { deviceMCP.presentSite() } label: {
                Text(String(localized: "retail_device_open"))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(AppTheme.wine)
        }
    }

    private func retryAction(_ errorCode: AssistantUiError) -> some View {
        Button {
            followLatestResponse()
            component.onRetryClicked()
        } label: {
            Text(String(localized: errorCode == AssistantUiError.retailAccessRequired
                ? "assistant_retry_after_access" : "assistant_retry"))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .foregroundStyle(AppTheme.wine)
    }

    private func accountSheet(_ state: AssistantState) -> some View {
        NavigationStack {
            Form {
                Section {
                    Text(state.account?.username ?? String(localized: state.account == nil ? "assistant_legacy_history" : "assistant_guest_account"))
                    if state.account?.expired == true { Text(String(localized: "assistant_account_expired")).foregroundStyle(AppTheme.bad) }
                    if state.account?.username == nil || state.account?.expired == true {
                        TextField(String(localized: "assistant_username"), text: $accountUsername)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        SecureField(String(localized: "assistant_password"), text: $accountPassword)
                        Button(String(localized: registerAccount ? "assistant_register" : "assistant_login")) {
                            component.onAccountSubmit(username: accountUsername, password: accountPassword, register: registerAccount)
                            accountPassword = ""
                        }.disabled(state.accountBusy || accountUsername.isEmpty || accountPassword.isEmpty)
                        Button(String(localized: registerAccount ? "assistant_login" : "assistant_register")) { registerAccount.toggle() }
                    }
                    if state.account == nil || (state.account?.expired == true && state.account?.username == nil) {
                        Button(String(localized: "assistant_continue_guest")) {
                            component.onAccountSubmit(username: "", password: "", register: false)
                        }.disabled(state.accountBusy)
                    } else {
                        Button(String(localized: "assistant_logout"), action: component.onLogoutClicked).disabled(state.accountBusy)
                    }
                    if state.accountBusy { ProgressView() }
                    if state.accountError { Text(String(localized: "assistant_account_failed")).foregroundStyle(AppTheme.bad) }
                }
            }
            .navigationTitle(String(localized: "assistant_account"))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(String(localized: "common_close")) { isAccountShown = false } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func storeChatItem(_ message: AssistantMessage, _ state: AssistantState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if message.kind == AssistantMessageKind.locationRequest {
                if message.text == "store_context_changed" {
                    Text(String(localized: "assistant_store_context_changed"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink2)
                }
                Label {
                    Text(String(localized: "assistant_location_card"))
                        .font(.subheadline.weight(.medium))
                } icon: {
                    AppIcon(systemName: "mappin.and.ellipse").font(.body.weight(.regular))
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { locationAction; addressAction }
                    VStack(alignment: .leading, spacing: 0) { locationAction; addressAction }
                }
            } else {
                Text(String(localized: message.kind == AssistantMessageKind.storeSelected ? "assistant_store_confirmed" : (message.stores.isEmpty ? "assistant_find_store" : "assistant_choose_store")))
                    .font(.subheadline.weight(.medium))
                if message.stores.isEmpty {
                    Text(String(localized: "assistant_no_store")).font(.subheadline).foregroundStyle(AppTheme.ink2)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { addressAction; locationAction }
                        VStack(alignment: .leading, spacing: 0) { addressAction; locationAction }
                    }
                }
                ForEach(message.stores, id: \.id) { store in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.name).font(.subheadline.weight(.medium))
                        Text(store.address).font(.footnote).foregroundStyle(AppTheme.ink2)
                        if let metres = store.distanceMetres {
                            Text(String(format: String(localized: "assistant_store_distance"), metres.intValue))
                                .font(.caption).foregroundStyle(AppTheme.muted)
                        }
                        if message.kind == AssistantMessageKind.storeCandidates {
                            Button(String(localized: "assistant_confirm_store")) {
                                followLatestResponse()
                                component.onStoreSelected(storeId: store.id)
                            }
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(AppTheme.wine)
                                .frame(minWidth: 44, minHeight: 44)
                                .disabled(state.phase != AssistantPhase.idle)
                        }
                    }
                }
                if message.kind == AssistantMessageKind.storeSelected {
                    Text(String(localized: message.storeVerified ? "assistant_store_verified" : "assistant_store_not_checked"))
                        .font(.caption).foregroundStyle(AppTheme.muted)
                    Button(String(localized: "assistant_change_store"), action: component.onLocationCardRequested)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.ink2)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(AppTheme.ink)
        .appMatteCard(cornerRadius: 16)
    }

    private var locationAction: some View {
        Button(String(localized: "assistant_locate_me"), action: component.onLocationRequested)
            .font(.footnote.weight(.medium))
            .foregroundStyle(AppTheme.wine)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 44, minHeight: 44)
    }

    private var addressAction: some View {
        Button(String(localized: "assistant_enter_address"), action: openAddressEntry)
            .font(.footnote)
            .foregroundStyle(AppTheme.ink2)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 44, minHeight: 44)
    }

    private var emptyConversation: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 24)
            Text(String(localized: "assistant_empty_title"))
                .font(.system(.largeTitle, design: .serif).weight(.medium))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
            Text(String(localized: "assistant_empty_body"))
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 28)
            VStack(spacing: 0) {
                addPhotoStarter
                Divider().overlay(AppTheme.rule).padding(.leading, 52)
                dinnerStarter
            }
            .padding(.horizontal, 16)
            .background(AppTheme.paper2, in: RoundedRectangle(cornerRadius: 20))
            Spacer(minLength: 48)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func starterLabel(_ title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: 16) {
            AppIcon(systemName: symbol)
                .font(.system(size: 22, weight: .regular))
                .frame(width: 24)
                .foregroundStyle(AppTheme.wine)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink)
                Text(detail).font(.footnote).foregroundStyle(AppTheme.muted)
            }
            Spacer(minLength: 0)
            AppIcon(systemName: "chevron.right").font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var addPhotoStarter: some View {
        Button(action: startPhotoSelection) {
            starterLabel(String(localized: "assistant_start_wine"),
                         detail: String(localized: "assistant_start_wine_detail"), symbol: "photo.on.rectangle")
        }
        .buttonStyle(.plain)
        .disabled(speechInput.isBusy || isPreparingPhotos ||
                  observableState.value.pendingAttachments > 0 || observableState.value.attachments.count >= 10)
    }

    private var dinnerStarter: some View {
        Button {
            component.onDraftChanged(text: String(localized: "assistant_starter_dinner_prompt"))
            // ObservableValue publishes shared changes on the next main turn. Focus
            // only after the new draft reaches the TextField, so it cannot commit its old empty value.
            DispatchQueue.main.async { isComposerFocused = true }
        } label: {
            starterLabel(String(localized: "assistant_start_dinner"),
                         detail: String(localized: "assistant_start_dinner_detail"), symbol: "fork.knife")
        }
        .buttonStyle(.plain)
    }

    private func composer(_ state: AssistantState) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if speechInput.isBusy {
                HStack(spacing: 8) {
                    AppIcon(systemName: speechInput.phase == .recording ? "waveform" : "mic")
                        .foregroundStyle(AppTheme.wine)
                    Text(speechStatus)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.ink2)
                    Spacer(minLength: 0)
                    Button(String(localized: "assistant_speech_cancel")) {
                        speechInput.cancel(discardTranscript: true)
                    }
                    .font(.footnote.weight(.medium))
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, 8)
            } else if let failure = speechInput.failure {
                Label(speechFailureText(failure), appSymbol: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.bad)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            composerContext(state)
            if let locationError = locationRequester.error {
                Text(locationError)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.bad)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !isAddressEntryShown && !state.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(state.attachments, id: \.id) { photo in
                            AssistantAttachmentView(
                                photo: photo,
                                onOpen: { openViewer(photo, in: state.attachments) },
                                onRemove: { component.onRemoveAttachment(id: photo.id) }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            if !isAddressEntryShown && (isPreparingPhotos || state.pendingAttachments > 0) {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(String(localized: "assistant_preparing_photos"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
                .accessibilityElement(children: .combine)
            }
            if isAddressEntryShown {
                HStack(spacing: 8) {
                    TextField(String(localized: "assistant_store_address"), text: $addressDraft)
                        .frame(minWidth: 44, minHeight: 44)
                        .textContentType(.fullStreetAddress)
                        .focused($isAddressFocused)
                        .submitLabel(.search)
                        .onSubmit(submitAddress)
                    Button(action: submitAddress) {
                        AppIcon(systemName: "magnifyingglass")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(String(localized: "assistant_find_store"))
                    .foregroundStyle(canSubmitAddress ? AppTheme.wine : AppTheme.muted)
                    .disabled(!canSubmitAddress)
                    Button(action: closeAddressEntry) {
                        AppIcon(systemName: "xmark")
                            .foregroundStyle(AppTheme.ink2)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(String(localized: "common_cancel"))
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .frame(minWidth: 44, minHeight: 44)
                .appGlass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    attachMenu(state)

                    TextField(
                        String(localized: "assistant_draft_hint"),
                        text: Binding(get: { state.draft }, set: { component.onDraftChanged(text: $0) }),
                        axis: .vertical
                    )
                    .lineLimit(1...5)
                    .focused($isComposerFocused)
                    .submitLabel(.send)
                    .onSubmit { if state.canSend && !speechInput.isBusy && !isPreparingPhotos { sendMessage() } }
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(speechInput.isBusy)

                    trailingComposerAction(state)
                }
                .buttonStyle(.plain)
                .padding(4)
                .appGlass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    private func canAddPhoto(_ state: AssistantState) -> Bool {
        !speechInput.isBusy && !isPreparingPhotos && state.pendingAttachments == 0 && state.attachments.count < 10
    }

    private func hasComposerContent(_ state: AssistantState) -> Bool {
        !state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !state.attachments.isEmpty || state.pendingAttachments > 0 || isPreparingPhotos
    }

    private func startPhotoSelection() {
        pickerConversationId = component.onPhotoSelectionStarted()
        isPickerShown = pickerConversationId != nil
    }

    private func startSpeech(_ state: AssistantState) {
        dropKeyboard()
        speechInput.start(draft: state.draft, locale: locale) { transcript in
            component.onDraftChanged(text: transcript)
        }
    }

    // A tap keeps the one-step photo flow; the menu keeps dictation reachable once the draft has text.
    private func attachMenu(_ state: AssistantState) -> some View {
        Menu {
            Button { startPhotoSelection() } label: {
                Label(String(localized: "assistant_add_photo"), appSymbol: "photo.on.rectangle")
            }
            .disabled(!canAddPhoto(state))
            Button { startSpeech(state) } label: {
                Label(String(localized: "assistant_speech_start"), appSymbol: "mic")
            }
        } label: {
            AppIcon(systemName: "plus")
                .font(.body.weight(.regular))
                .foregroundStyle(canAddPhoto(state) ? AppTheme.ink2 : AppTheme.muted)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        } primaryAction: {
            if canAddPhoto(state) { startPhotoSelection() }
        }
        .disabled(speechInput.isBusy)
        .accessibilityLabel(String(localized: "assistant_add_photo"))
        .accessibilityAction(named: Text(String(localized: "assistant_speech_start"))) { startSpeech(state) }
    }

    @ViewBuilder
    private func trailingComposerAction(_ state: AssistantState) -> some View {
        if speechInput.isBusy {
            Button { speechInput.stop() } label: {
                AppIcon(systemName: "stop.fill")
                    .font(.body.weight(.regular))
                    .foregroundStyle(AppTheme.onWine)
                    .frame(width: 44, height: 44)
                    .background(speechInput.phase == .recording ? AppTheme.wine : AppTheme.muted, in: Circle())
            }
            .disabled(speechInput.phase != .recording)
            .accessibilityLabel(String(localized: "assistant_speech_stop"))
        } else if hasComposerContent(state) {
            let canSend = state.canSend && !isPreparingPhotos
            Button(action: sendMessage) {
                AppIcon(systemName: "paperplane")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canSend ? AppTheme.onWine : AppTheme.muted)
                    .frame(width: 44, height: 44)
                    .background(canSend ? AppTheme.wine : AppTheme.paper2, in: Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel(String(localized: "assistant_send"))
        } else {
            Button { startSpeech(state) } label: {
                AppIcon(systemName: "mic")
                    .font(.body.weight(.regular))
                    .foregroundStyle(AppTheme.ink2)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .accessibilityLabel(String(localized: "assistant_speech_start"))
        }
    }

    @ViewBuilder
    private func composerContext(_ state: AssistantState) -> some View {
        let wine = state.selectedWine
        if let store = state.selectedStore {
            Menu {
                if let wine {
                    Section(String(localized: "assistant_selected_wine")) {
                        Label(wineIdentity(wine), appSymbol: "wineglass")
                    }
                }
                Section([store.name, store.address].joined(separator: " · ")) {
                    if deviceMCP.supported {
                        Button(String(localized: "retail_device_open")) { deviceMCP.presentSite() }
                    }
                    Button(String(localized: "assistant_change_store"), action: component.onLocationCardRequested)
                    Button(String(localized: "assistant_locate_me"), action: component.onLocationRequested)
                    Button(String(localized: "assistant_enter_address")) {
                        openAddressEntry()
                    }
                }
            } label: {
                contextRow(wine: wine, place: store.name, placeSymbol: "basket", isMenu: true)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .accessibilityLabel(contextAccessibilityLabel(wine: wine, place: "\(store.name), \(store.address)"))
        } else if wine != nil || state.location != nil {
            contextRow(wine: wine, place: state.location?.address, placeSymbol: "mappin.and.ellipse", isMenu: false)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(contextAccessibilityLabel(wine: wine, place: state.location?.address))
        }
    }

    private func wineIdentity(_ wine: AssistantWine) -> String {
        [wine.title, wine.producer].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    // Two wines can share a name; the producer tells them apart, so it gives way to the title last.
    private func contextRow(wine: AssistantWine?, place: String?, placeSymbol: String, isMenu: Bool) -> some View {
        HStack(spacing: 6) {
            if let wine {
                AppIcon(systemName: "wineglass").font(.footnote.weight(.regular))
                Text(wine.title).lineLimit(1).layoutPriority(2)
                if let producer = wine.producer, !producer.isEmpty {
                    Text(producer).lineLimit(1).foregroundStyle(AppTheme.muted).layoutPriority(1)
                }
            }
            if wine != nil && place != nil {
                Text(verbatim: "·").foregroundStyle(AppTheme.muted)
            }
            if let place {
                AppIcon(systemName: placeSymbol).font(.footnote.weight(.regular))
                Text(place).lineLimit(1)
            }
            Spacer(minLength: 0)
            if isMenu {
                AppIcon(systemName: "chevron.down").font(.caption.weight(.regular))
            }
        }
        .font(.footnote)
        .foregroundStyle(AppTheme.ink2)
    }

    private func contextAccessibilityLabel(wine: AssistantWine?, place: String?) -> String {
        [wine.map { String(format: String(localized: "assistant_context_wine_a11y"), wineIdentity($0)) }, place]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private var speechStatus: String {
        if speechInput.phase == .authorizing { return String(localized: "assistant_speech_authorizing") }
        if speechInput.phase == .finishing { return String(localized: "assistant_speech_finishing") }
        return String(localized: "assistant_speech_recording")
    }

    private func speechFailureText(_ failure: AssistantSpeechInput.Failure) -> String {
        switch failure {
        case .speechPermissionDenied:
            String(localized: "assistant_speech_permission_denied")
        case .microphonePermissionDenied:
            String(localized: "assistant_microphone_permission_denied")
        case .onDeviceUnavailable:
            String(localized: "assistant_speech_on_device_unavailable")
        case .unavailable:
            String(localized: "assistant_speech_unavailable")
        case .recordingFailed:
            String(localized: "assistant_speech_recording_failed")
        case .recognitionFailed:
            String(localized: "assistant_speech_recognition_failed")
        }
    }

    private func closeDrawer() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            isDrawerShown = false
        }
    }

    private func phaseText(_ phase: AssistantPhase) -> String {
        if phase == AssistantPhase.recognizing { return String(localized: "assistant_phase_recognizing") }
        if phase == AssistantPhase.searchingStore { return String(localized: "assistant_phase_searching") }
        if phase == AssistantPhase.replacingProduct { return String(localized: "assistant_phase_replacing") }
        if phase == AssistantPhase.selectingDinner { return String(localized: "assistant_phase_selecting_dinner") }
        return String(localized: "assistant_phase_thinking")
    }

    private func openAddressEntry() {
        dropKeyboard()
        addressDraft = observableState.value.location?.address ?? ""
        isAddressEntryShown = true
        let conversationId = observableState.value.conversationId
        DispatchQueue.main.async {
            guard isAddressEntryShown,
                  observableState.value.conversationId == conversationId else { return }
            isAddressFocused = true
        }
    }

    private func closeAddressEntry() {
        let wasFocused = isAddressFocused
        isAddressFocused = false
        isAddressEntryShown = false
        addressDraft = ""
        if wasFocused { Keyboard.dismiss() }
    }

    private var canSubmitAddress: Bool {
        !addressDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitAddress() {
        let address = addressDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return }
        closeAddressEntry()
        followLatestResponse()
        component.onAddressEntered(address: address)
    }

    private func openViewer(_ photo: AssistantPhoto, in photos: [AssistantPhoto]) {
        viewerPhotos = photos
        viewerIndex = photos.firstIndex { $0.id == photo.id } ?? 0
        selectedPhoto = photo
    }

    private func moveViewer(by step: Int) {
        let next = viewerIndex + step
        guard viewerPhotos.indices.contains(next) else { return }
        viewerIndex = next
        selectedPhoto = viewerPhotos[next]
    }

    private func attachPickedPhotos(_ items: [PhotosPickerItem], conversationId: String) async {
        let capacity = remainingPhotoCapacity(observableState.value)
        var failed = false
        for item in items.prefix(capacity) {
            guard observableState.value.conversationId == conversationId else { break }
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                failed = true
                continue
            }
            let path = await Task.detached(priority: .userInitiated) {
                PhotoPreparer.prepare(data: data)
            }.value
            if let path {
                if observableState.value.conversationId == conversationId {
                    component.onAttachmentPicked(photoPath: path)
                } else {
                    try? FileManager.default.removeItem(atPath: path)
                }
            } else {
                failed = true
            }
        }
        if observableState.value.conversationId == conversationId {
            photoImportNotice = failed ? .failed : (items.count > capacity ? .limit : nil)
        }
        pickerItems = []
        pickerConversationId = nil
        isPreparingPhotos = false
    }
}
