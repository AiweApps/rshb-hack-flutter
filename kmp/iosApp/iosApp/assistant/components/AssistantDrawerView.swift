import SwiftUI
import SharedLogic

/// Local slide-over navigation for assistant conversations and choices.
/// Every selection is delegated to the shared component by the caller.
struct AssistantDrawerView: View {
    private enum Section: CaseIterable, Hashable {
        case conversations
        case wines
        case stores

        var title: String {
            switch self {
            case .conversations: String(localized: "assistant_conversations")
            case .wines: String(localized: "assistant_saved_wines")
            case .stores: String(localized: "assistant_stores")
            }
        }

        var symbol: String {
            switch self {
            case .conversations: "bubble.left.and.bubble.right"
            case .wines: "wineglass"
            case .stores: "basket"
            }
        }
    }

    @State private var section: Section = .conversations
    let state: AssistantState
    let onClose: () -> Void
    let onNewConversation: () -> Void
    let onConversationSelect: (String) -> Void
    let onWineSelect: (AssistantWine) -> Void
    let onStoreSelect: (AssistantStore) -> Void
    let onUseLocation: () -> Void
    let onEnterAddress: () -> Void
    let onOpenScanHistory: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Button(action: onClose) {
                    Color.black.opacity(0.42)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "assistant_drawer_close"))

                panel
                    .padding(.top, geometry.safeAreaInsets.top)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                    .frame(width: min(geometry.size.width * 0.86, 360))
                    .frame(maxHeight: .infinity)
                    .background(AppTheme.paper)
                    .overlay(alignment: .trailing) {
                        Rectangle().fill(AppTheme.rule).frame(width: 1)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "assistant_drawer_title"))
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Spacer(minLength: 8)
                Button(action: onClose) {
                    AppIcon(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "assistant_drawer_close"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Button(action: onNewConversation) {
                Label(String(localized: "assistant_new_conversation"), appSymbol: "square.and.pencil")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.wine)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            HStack(spacing: 0) {
                ForEach([Section.conversations, .wines], id: \.self) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { section = item }
                    } label: {
                        HStack(spacing: 6) {
                            Text(item.title)
                            let count = item == .conversations ? state.conversations.count : state.savedWines.count
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(section == item ? AppTheme.wine : AppTheme.ink2)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(alignment: .bottom) {
                            if section == item { Rectangle().fill(AppTheme.wine).frame(height: 2) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(section == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)

            ScrollView {
                Group {
                    switch section {
                    case .conversations: conversations
                    case .wines: wines
                    case .stores: stores
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().overlay(AppTheme.rule)
            Button {
                section = .stores
            } label: {
                HStack(spacing: 12) {
                    AppIcon(systemName: Section.stores.symbol).frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Section.stores.title).font(.subheadline)
                        if let store = state.selectedStore {
                            Text(store.address).font(.caption).foregroundStyle(AppTheme.muted).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 4)
                    AppIcon(systemName: "chevron.right").font(.caption)
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .contentShape(Rectangle())
            }
            .background(section == .stores ? AppTheme.paper2 : .clear)
            Button(action: onOpenScanHistory) {
                Label(String(localized: "tab_history"), appSymbol: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .contentShape(Rectangle())
            }
            Button(action: onOpenSettings) {
                Label(String(localized: "tab_settings"), appSymbol: "gearshape")
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.ink2)
        .padding(.horizontal, 16)
    }

    private var conversations: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if state.conversations.isEmpty {
                emptyState("bubble.left.and.bubble.right", String(localized: "assistant_drawer_conversations_empty"))
            } else {
                ForEach(state.conversations, id: \.id) { conversation in
                    Button { onConversationSelect(conversation.id) } label: {
                        HStack(spacing: 10) {
                            Text(displayedTitle(conversation))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if state.conversationId == conversation.id {
                                AppIcon(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.wine)
                                    .accessibilityLabel(String(localized: "assistant_drawer_current"))
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 10)
                        .background(state.conversationId == conversation.id ? AppTheme.paper2 : .clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var wines: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if state.savedWines.isEmpty {
                emptyState("heart", String(localized: "assistant_drawer_wines_empty"))
            } else {
                ForEach(state.savedWines, id: \.presentationIdentity) { wine in
                    Button { onWineSelect(wine) } label: {
                        HStack(spacing: 12) {
                            wineArtwork(wine)
                                .frame(width: 48, height: 70)
                                .background(AppTheme.card)
                                .clipped()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(wine.title)
                                    .font(AppTheme.wineTitle)
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(2)
                                if let producer = wine.producer, !producer.isEmpty {
                                    Text(producer)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.ink2)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 4)
                            if state.selectedWine?.presentationIdentity == wine.presentationIdentity {
                                AppIcon(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.wine)
                                    .accessibilityLabel(String(localized: "assistant_selected_wine"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func wineArtwork(_ wine: AssistantWine) -> some View {
        if let reference = wine.reference, let access = state.referenceAccess {
            AuthorizedAsyncImage(url: access.resolve(reference: reference), access: access) {
                ProgressView()
            } failure: {
                winePhotoOrSymbol(wine)
            }
            .padding(3)
        } else {
            winePhotoOrSymbol(wine)
        }
    }

    @ViewBuilder
    private func winePhotoOrSymbol(_ wine: AssistantWine) -> some View {
        if let path = wine.photoPath {
            LocalPhotoView(path: path, maxPixel: 160) {
                AppIcon(systemName: "wineglass").foregroundStyle(AppTheme.wine)
            }
        } else {
            AppIcon(systemName: "wineglass")
                .font(.title3.weight(.light))
                .foregroundStyle(AppTheme.wine)
        }
    }

    private var stores: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            sectionTitle(Section.stores.title, count: state.availableStores.count)
            if state.availableStores.isEmpty {
                emptyState("basket", String(localized: "assistant_drawer_stores_empty"))
            } else {
                ForEach(state.availableStores, id: \.id) { store in
                    Button { onStoreSelect(store) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            AppIcon(systemName: "basket")
                                .foregroundStyle(AppTheme.wine)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.ink)
                                Text(store.address)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.ink2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 4)
                            if state.selectedStore?.id == store.id {
                                AppIcon(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.wine)
                                    .accessibilityLabel(String(localized: "assistant_drawer_store_selected"))
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(state.selectedStore?.id == store.id ? AppTheme.paper2 : .clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().overlay(AppTheme.rule)
                .padding(.vertical, 8)
            Button(action: onUseLocation) {
                Label(String(localized: "assistant_use_location"), appSymbol: "location")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            Button(action: onEnterAddress) {
                Label(String(localized: "assistant_enter_address"), appSymbol: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .padding(.top, 2)
            .foregroundStyle(AppTheme.wine)
        }
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func displayedTitle(_ conversation: AssistantConversation) -> String {
        if conversation.title.isEmpty ||
            (conversation.title == "Новый разговор" && conversation.lastMessage.isEmpty) {
            return String(localized: "assistant_new_conversation")
        }
        return conversation.title
    }

    private func emptyState(_ symbol: String, _ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AppIcon(systemName: symbol)
                .font(.title2.weight(.light))
                .foregroundStyle(AppTheme.wine)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
}
