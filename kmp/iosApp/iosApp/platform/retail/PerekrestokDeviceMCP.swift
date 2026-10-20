import SwiftUI
import WebKit
import SharedLogic

/// App-lifetime native session adapted from perekrestok-device-mcp PR #2 (5ba16d7).
/// The retailer's credentials stay in WKWebView page memory. Only bounded product data leaves it.
@MainActor
final class PerekrestokDeviceMCP: NSObject, ObservableObject {
    static let shared = PerekrestokDeviceMCP()
    static let origin = "https://www.perekrestok.ru"
    private static let preferenceKey = "retail_device_mcp_enabled_v1"
    #if targetEnvironment(simulator)
    let supported = false
    #else
    let supported = true
    #endif
    @Published private(set) var enabled: Bool
    @Published private(set) var status: Status = .notOpened
    enum Status { case notOpened, loading, ready, attention, disabled }
    private(set) var foreground = false
    private var runningKey: String?
    private var generation = 0
    private var navigationGeneration = 0
    private var requiresUserAction = false
    private var bridge: RetailDeviceBridge?
    private var view: WKWebView?
    private weak var presentation: UIViewController?
    private var commandScript: String { Self.resource("retail-command") }

    override private init() {
        #if targetEnvironment(simulator)
        enabled = false
        #else
        enabled = UserDefaults.standard.object(forKey: Self.preferenceKey) as? Bool ?? true
        #endif
        super.init()
        if !enabled { status = .disabled }
    }

    func configure(baseURL: URL) {
        bridge = RetailDeviceBridge(owner: self, baseURL: baseURL)
    }

    func setEnabled(_ value: Bool) {
        guard supported else { return }
        enabled = value
        UserDefaults.standard.set(value, forKey: Self.preferenceKey)
        generation += 1
        if value {
            requiresUserAction = false
            status = .notOpened
            if foreground { bridge?.start() }
        } else {
            abort()
            bridge?.stop()
            view?.stopLoading()
            status = .disabled
        }
    }

    func setForeground(_ active: Bool) {
        foreground = active
        if active && supported && enabled { bridge?.start() }
        else {
            generation += 1
            abort()
            bridge?.stop()
        }
    }

    private func abort() {
        guard let key = runningKey else { return }
        // Key is locally generated UUID, never remote text.
        let web = view
        Task { @MainActor in
            _ = try? await web?.callAsyncJavaScript("window.__retailProbeSession?.jobs?.[jobKey]?.abort('app_backgrounded');",
                                 arguments: ["jobKey": key], in: nil, contentWorld: .page)
        }
    }

    var webView: WKWebView {
        if let view { return view }
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.userContentController.addUserScript(WKUserScript(source: Self.resource("retail-session-hook"),
            injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .page))
        config.userContentController.add(RetailSessionMessageProxy(self), contentWorld: .page, name: "retailSession")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isInspectable = false
        web.navigationDelegate = self
        web.allowsBackForwardNavigationGestures = true
        view = web
        return web
    }

    /// Explicit user action is the only recovery from a challenge. It does not clear cookies.
    func openSite() {
        guard supported, enabled, foreground else { return }
        if status != .ready || !Self.isTrusted(view?.url) {
            requiresUserAction = false
            status = .loading
            webView.load(URLRequest(url: URL(string: Self.origin)!))
        }
    }

    func reloadSite() {
        guard supported, enabled, foreground else { return }
        navigationGeneration += 1
        abort()
        requiresUserAction = false
        status = .loading
        webView.load(URLRequest(url: URL(string: Self.origin)!))
    }

    func presentSite() {
        guard supported, foreground else { return }
        guard presentation == nil else { return }
        let host = UIHostingController(rootView: RetailDeviceAccessView(session: self, close: { [weak self] in
            self?.presentation?.dismiss(animated: true)
        }))
        let root = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController
        var presenter = root
        while let presented = presenter?.presentedViewController { presenter = presented }
        presentation = host
        presenter?.present(host, animated: true)
        openSite()
    }

    func execute(_ command: RetailDeviceCommand) async -> [String: Any] {
        guard supported, enabled, foreground else { return Self.failure("device_offline") }
        guard runningKey == nil else { return Self.failure("device_busy") }
        let key = UUID().uuidString
        runningKey = key
        defer { if runningKey == key { runningKey = nil } }
        let lifecycle = generation
        if status == .notOpened { openSite() }
        let deadline = Date().addingTimeInterval(10)
        while status == .loading && Date() < deadline && enabled && foreground && !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard enabled, foreground, lifecycle == generation, !Task.isCancelled else { return Self.failure("device_offline") }
        guard status == .ready, !requiresUserAction, Self.isTrusted(view?.url) else { return Self.failure("retailer_session_not_ready") }
        if let expiry = command.expiresAt, expiry <= Date() { return Self.failure("command_expired") }
        let pageGeneration = navigationGeneration
        do {
            let raw = try await webView.callAsyncJavaScript(commandScript,
                arguments: ["COMMAND": command.scriptArgument, "jobKey": key], in: nil, contentWorld: .page)
            guard enabled, foreground, lifecycle == generation, pageGeneration == navigationGeneration, !Task.isCancelled else { return Self.failure("device_offline") }
            guard let text = raw as? String, let data = text.data(using: .utf8), data.count <= 256_000,
                  let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return Self.failure("invalid_native_result")
            }
            if let error = object["error"] as? String {
                let code: String
                switch error {
                case "challenge_or_block", "non_json_response", "http_401", "session_not_ready":
                    requiresUserAction = true
                    status = .attention
                    code = "challenge_or_block"
                case "store_mapping_mismatch", "store_selection_mismatch", "store_mismatch": code = "store_mismatch"
                case "timeout": code = "device_timeout"
                default: code = "retailer_request_failed"
                }
                return Self.failure(code)
            }
            return RetailDeviceEnvelope.validated(object, command: command) ?? Self.failure("invalid_native_result")
        } catch {
            guard enabled, foreground, lifecycle == generation else { return Self.failure("device_offline") }
            return Self.failure("retailer_session_not_ready")
        }
    }

    fileprivate func ready(_ message: WKScriptMessage) {
        guard enabled, foreground, !requiresUserAction,
              message.frameInfo.isMainFrame, Self.isTrusted(message.frameInfo.request.url),
              Self.isTrusted(view?.url), (message.body as? [String: Any])?["ready"] as? Bool == true else { return }
        status = .ready
    }

    static func failure(_ code: String) -> [String: Any] { ["error": code] }
    static func isTrusted(_ url: URL?) -> Bool {
        url?.scheme == "https" && url?.host == "www.perekrestok.ru" && (url?.port == nil || url?.port == 443)
            && url?.user == nil && url?.password == nil
    }
    private static func resource(_ name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "js"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "return JSON.stringify({error:'missing_resource'});" }
        return text
    }
}

extension PerekrestokDeviceMCP: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        (action.targetFrame?.isMainFrame ?? true) && !Self.isTrusted(action.request.url) ? .cancel : .allow
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Initial command can load the page. Any subsequent navigation invalidates its active JS result.
        navigationGeneration += 1
        if enabled { status = .loading }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard enabled else { return }
        let currentNavigation = navigationGeneration
        webView.evaluateJavaScript("({ready:Boolean(window.__retailProbeSession?.ready()), blocked:(document.body?.innerText||'').includes('Проблемы со связью')})") { [weak self] raw, _ in
            guard let self, self.enabled, self.navigationGeneration == currentNavigation else { return }
            let probe = raw as? [String: Any]
            guard !self.requiresUserAction else { self.status = .attention; return }
            if probe?["blocked"] as? Bool == true { self.requiresUserAction = true }
            self.status = probe?["blocked"] as? Bool == true ? .attention : (probe?["ready"] as? Bool == true ? .ready : .attention)
        }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if enabled { status = .attention }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if enabled { status = .attention }
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        generation += 1
        if enabled { status = .attention }
    }
}

private final class RetailSessionMessageProxy: NSObject, WKScriptMessageHandler {
    weak var owner: PerekrestokDeviceMCP?
    init(_ owner: PerekrestokDeviceMCP) { self.owner = owner }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated { owner?.ready(message) }
    }
}
