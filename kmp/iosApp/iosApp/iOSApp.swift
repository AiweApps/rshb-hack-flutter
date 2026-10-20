import FirebaseCore
import SwiftUI
import SharedLogic

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(component: appDelegate.rootComponent)
                .environmentObject(PerekrestokDeviceMCP.shared)
        }
        // A scene-based app never calls the delegate's did-become-active/will-resign-active,
        // so the Decompose lifecycle is driven from the scene phase: components that start
        // and stop work on resume/pause (the camera, the status poll) depend on it.
        .onChange(of: scenePhase, initial: true) { _, phase in
            PerekrestokDeviceMCP.shared.setForeground(phase == .active)
            switch phase {
            case .active:
                LifecycleRegistryExtKt.resume(appDelegate.lifecycle)
            case .inactive:
                LifecycleRegistryExtKt.pause(appDelegate.lifecycle)
            case .background:
                LifecycleRegistryExtKt.stop(appDelegate.lifecycle)
                appDelegate.localScanEngine.releaseModels()
            @unknown default:
                break
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let lifecycle = LifecycleRegistryKt.LifecycleRegistry()
    let localScanEngine = AppleLocalScanEngine()
    var rootComponent: RootComponent!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // First, so Crashlytics already catches a crash during the Koin start below.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }

        // Kotlin has no BuildConfig on iOS, so the build kind is passed in from here.
        #if DEBUG
        let isDebug = true
        let assistantBaseUrl = ProcessInfo.processInfo.environment["WINE_ASSISTANT_BASE_URL"] ?? "https://wines.aiweapps.com/assistant/"
        let assistantAccessToken: String? = nil
        #else
        let isDebug = false
        let assistantBaseUrl: String? = "https://wines.aiweapps.com/assistant/"
        let assistantAccessToken: String? = nil
        #endif
        let retail = PerekrestokDeviceMCP.shared
        retail.configure(baseURL: URL(string: assistantBaseUrl ?? "https://wines.aiweapps.com/assistant/")!)
        let info = Bundle.main.infoDictionary
        #if WINE_SCANNER_LOCAL
        let scannerBuild = ScannerBuild.local
        #else
        let scannerBuild = ScannerBuild.server
        #endif
        Koin_iosKt.doInitKoinIos(
            isDebug: isDebug,
            appVersion: info?["CFBundleShortVersionString"] as? String ?? "",
            appBuild: info?["CFBundleVersion"] as? String ?? "",
            platformShare: AppleShare(),
            platformLinks: AppleLinks(retail: retail),
            platformLanguage: AppleLanguage(),
            assistantBaseUrl: assistantBaseUrl,
            assistantAccessToken: assistantAccessToken,
            retailGateway: AppleRetailGateway(session: retail),
            analyticsTracker: AppleAnalytics(),
            scannerBuild: scannerBuild,
            localScanEngine: localScanEngine
        )

        let componentContext = DefaultComponentContext(lifecycle: lifecycle)
        rootComponent = Koin_iosKt.createRootComponent(componentContext: componentContext)

        LifecycleRegistryExtKt.create(lifecycle)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        LifecycleRegistryExtKt.destroy(lifecycle)
    }
}
