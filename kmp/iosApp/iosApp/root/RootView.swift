import SwiftUI
import SharedLogic

/// One pushed screen (result, wine, dish pairing): the index of its entry in the
/// Decompose stack, plus the kind so a different screen at the same index is a new route.
struct PushedRoute: Hashable {
    let stackIndex: Int
    let kind: String
}

/// Renders `RootComponent.childStack`. Splash, onboarding and the tabs replace each other;
/// every other child is pushed inside the selected tab's navigation stack, with the tab bar
/// hidden underneath it.
struct RootView: View {
    @ObservedObject private var childStack: ObservableValue<ChildStack<AnyObject, RootComponentChild>>
    @ObservedObject private var themeMode: ObservableValue<ThemeMode>

    init(component: RootComponent) {
        self.childStack = ObservableValue(component.childStack)
        self.themeMode = ObservableValue(component.themeMode)
    }

    var body: some View {
        let items = childStack.value.items.map { $0.instance }
        let base = items.last { !Self.isPushed($0) }
        let routes = items.enumerated().compactMap { index, child in
            Self.isPushed(child)
                ? PushedRoute(stackIndex: index, kind: String(describing: type(of: child)))
                : nil
        }

        baseContent(base, routes: routes, items: items)
            // A sibling above TabView/NavigationStack covers their bars without removing
            // them from layout. The chat keeps its native safe area while the menu moves.
            .overlayPreferenceValue(AssistantDrawerOverlayKey.self) { drawer in
                if let drawer {
                    drawer
                        .ignoresSafeArea(.keyboard)
                        .accessibilityAddTraits(.isModal)
                        .zIndex(100)
                }
            }
            .preferredColorScheme(colorScheme)
            .tint(AppTheme.wine)
    }

    @ViewBuilder
    private func baseContent(
        _ child: RootComponentChild?,
        routes: [PushedRoute],
        items: [RootComponentChild]
    ) -> some View {
        Group {
            if child is RootComponentChild.Splash {
                SplashView()
            } else if let onboarding = child as? RootComponentChild.Onboarding {
                OnboardingView(component: onboarding.component)
            } else if let main = child as? RootComponentChild.Main {
                MainView(
                    component: main.component,
                    pushedPath: pathBinding(routes: routes, items: items)
                ) { route in
                    pushedScreen(route, items: items)
                }
            } else {
                AppTheme.paper.ignoresSafeArea()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: child.map { String(describing: type(of: $0)) })
    }

    @ViewBuilder
    private func pushedScreen(_ route: PushedRoute, items: [RootComponentChild]) -> some View {
        if route.stackIndex < items.count {
            let child = items[route.stackIndex]
            if let result = child as? RootComponentChild.ScanResult {
                ScanResultView(component: result.component)
            } else if let detail = child as? RootComponentChild.WineDetail {
                WineDetailView(component: detail.component)
            } else if let pairing = child as? RootComponentChild.DishPairing {
                DishPairingView(component: pairing.component)
            }
        }
    }

    /// Everything above the tabs: not splash, onboarding or main.
    private static func isPushed(_ child: RootComponentChild) -> Bool {
        child is RootComponentChild.ScanResult
            || child is RootComponentChild.WineDetail
            || child is RootComponentChild.DishPairing
    }

    private var colorScheme: ColorScheme? {
        let mode = themeMode.value
        if mode == ThemeMode.light {
            return .light
        } else if mode == ThemeMode.dark {
            return .dark
        } else {
            return nil
        }
    }

    /// SwiftUI pops (back swipe, back button) arrive as a shorter path; they are handed to
    /// the top component, which owns the stack.
    private func pathBinding(routes: [PushedRoute], items: [RootComponentChild]) -> Binding<[PushedRoute]> {
        Binding(
            get: { routes },
            set: { newPath in
                guard newPath.count < routes.count, let top = items.last else { return }
                if let result = top as? RootComponentChild.ScanResult {
                    result.component.onBackClicked()
                } else if let detail = top as? RootComponentChild.WineDetail {
                    detail.component.onBackClicked()
                } else if let pairing = top as? RootComponentChild.DishPairing {
                    pairing.component.onBackClicked()
                }
            }
        )
    }
}
