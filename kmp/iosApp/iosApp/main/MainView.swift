import SwiftUI
import SharedLogic

private let scanTabIndex = 0
private let assistantTabIndex = 4

/// Three primary destinations; scan history and settings stay secondary (side menu of the assistant). Each destination owns its title bar; pushed
/// screens (result, pairing) go onto the selected tab's stack and hide the tab bar.
struct MainView<PushedScreen: View>: View {
    @ObservedObject private var pages: ObservableValue<ChildPages<AnyObject, MainComponentTabChild>>
    @ObservedObject private var compareCount: ObservableValue<KotlinInt>
    private let component: MainComponent
    private let pushedPath: Binding<[PushedRoute]>
    private let pushedScreen: (PushedRoute) -> PushedScreen

    init(
        component: MainComponent,
        pushedPath: Binding<[PushedRoute]>,
        @ViewBuilder pushedScreen: @escaping (PushedRoute) -> PushedScreen
    ) {
        self.component = component
        self.compareCount = ObservableValue(component.compareCount)
        self.pages = ObservableValue(component.pages)
        self.pushedPath = pushedPath
        self.pushedScreen = pushedScreen
    }

    private var compareBadge: Int {
        Int(truncating: compareCount.value)
    }

    var body: some View {
        let current = pages.value
        let selected = Int(current.selectedIndex)
        let selection = Binding<Int>(
            get: { selected },
            set: { component.selectTab(index: Int32($0)) }
        )

        if selected == 1 || selected == 3 {
            stack(current.items, index: selected, selected: selected)
        } else {
            tabs(items: current.items, selected: selected, selection: selection)
        }
    }

    @ViewBuilder
    private func tabs(
        items: [Child<AnyObject, MainComponentTabChild>],
        selected: Int,
        selection: Binding<Int>
    ) -> some View {
        let view = TabView(selection: selection) {
            Tab(value: 4) {
                stack(items, index: 4, selected: selected)
            } label: {
                tabLabel(String(localized: "assistant_ios_tab_title"), symbol: "bubble.left")
            }
            Tab(value: 0) {
                stack(items, index: 0, selected: selected)
            } label: {
                tabLabel(String(localized: "tab_scan"), symbol: "camera.viewfinder")
            }
            Tab(value: 2) {
                stack(items, index: 2, selected: selected)
            } label: {
                tabLabel(String(localized: "tab_compare"), symbol: "arrow.left.arrow.right")
            }
            .badge(compareBadge)
        }
        if #available(iOS 26, *) {
            // Keep the three destinations stable while reading or composing a conversation.
            // The system owns the neutral glass selection capsule; only its label is tinted.
            view.tabBarMinimizeBehavior(.never)
                .tint(AppTheme.wine)
        } else {
            view
        }
    }

    private func tabLabel(_ title: String, symbol: String) -> some View {
        Label {
            Text(title)
        } icon: {
            if let image = OutlineTabGlyphs.images[symbol] {
                Image(uiImage: image).renderingMode(.template)
            }
        }
    }

    /// Every tab keeps one navigation stack for good. The stacks share one binding shape: it
    /// reads the pushed path for the selected tab and an empty path for the others, so a tab
    /// switch changes no stack's value (the tab bar is hidden while a pushed screen is up,
    /// so the selection cannot change underneath one).
    ///
    /// The title is set here, around the page, as well as inside it: a tab whose component
    /// has not been created yet shows a blank placeholder first, and a bar that gets its
    /// title only with the real page animates it in from the top. The assistant sets its own.
    ///
    /// The tab bar follows the stack's path from out here, with its own animation, rather
    /// than from the pushed screen: the screen's modifier makes the bar come back without
    /// animation once the screen is gone.
    private func stack(
        _ items: [Child<AnyObject, MainComponentTabChild>],
        index: Int,
        selected: Int
    ) -> some View {
        let path = tabPath(index: index, selected: selected)
        let hasPushed = !path.wrappedValue.isEmpty

        return NavigationStack(path: path) {
            page(items, index: index)
                .toolbar {
                    if index == 1 || index == 3 {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { component.selectTab(index: Int32(assistantTabIndex)) } label: {
                                AppIcon(systemName: "chevron.left")
                            }
                            .buttonBorderShape(.circle)
                            .accessibilityLabel(String(localized: "common_back"))
                        }
                    }
                }
                .modifier(TabTitle(index: index))
                .navigationDestination(for: PushedRoute.self) { route in
                    pushedScreen(route)
                }
        }
        .toolbarVisibility(hasPushed ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.3), value: hasPushed)
    }

    private func tabPath(index: Int, selected: Int) -> Binding<[PushedRoute]> {
        Binding(
            get: { index == selected ? pushedPath.wrappedValue : [] },
            set: { newPath in
                if index == selected {
                    pushedPath.wrappedValue = newPath
                }
            }
        )
    }

    /// A tab that has not been created yet has no instance; it renders nothing until it has.
    @ViewBuilder
    private func page(_ items: [Child<AnyObject, MainComponentTabChild>], index: Int) -> some View {
        if index < items.count, let child = items[index].instance {
            if let scan = child as? MainComponentTabChild.Scan {
                ScanHomeView(component: scan.component)
            } else if let history = child as? MainComponentTabChild.History {
                HistoryView(component: history.component)
            } else if let compare = child as? MainComponentTabChild.Compare {
                WineCompareView(component: compare.component)
            } else if let settings = child as? MainComponentTabChild.Settings {
                SettingsView(component: settings.component)
            } else if let assistant = child as? MainComponentTabChild.Assistant {
                AssistantView(
                    component: assistant.component,
                    onOpenScanHistory: { component.selectTab(index: 1) },
                    onOpenSettings: { component.selectTab(index: 3) }
                )
            }
        } else {
            Color.clear
        }
    }
}

/// Tab images are custom template assets; TabView cannot substitute filled SF variants.
private enum OutlineTabGlyphs {
    static let images: [String: UIImage] = {
        var result: [String: UIImage] = [:]
        for name in ["bubble.left", "camera.viewfinder", "arrow.left.arrow.right"] {
            result[name] = AppIconCatalog.image(for: name)
        }
        return result
    }()
}

/// The tab's title and its display mode; the assistant brings its own title bar.
private struct TabTitle: ViewModifier {
    let index: Int

    func body(content: Content) -> some View {
        switch index {
        case assistantTabIndex:
            content
        case scanTabIndex:
            content
                .navigationTitle(String(localized: "tab_scan"))
                .navigationBarTitleDisplayMode(.inline)
        default:
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
        }
    }

    private var title: String {
        switch index {
        case 1: String(localized: "history_title")
        case 2: String(localized: "compare_title")
        default: String(localized: "settings_title")
        }
    }
}
