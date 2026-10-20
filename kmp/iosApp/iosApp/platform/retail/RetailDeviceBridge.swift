import Foundation
import SharedLogic

/// Outbound HTTPS channel, identical account/device identity to chat. No LAN pairing or listener.
@MainActor
final class RetailDeviceBridge {
    private weak var owner: PerekrestokDeviceMCP?
    private let baseURL: URL
    private var polling: Task<Void, Never>?
    private let redirectPolicy = RetailNoRedirect()
    private lazy var session = URLSession(configuration: .ephemeral, delegate: redirectPolicy, delegateQueue: nil)

    init(owner: PerekrestokDeviceMCP, baseURL: URL) {
        self.owner = owner
        self.baseURL = baseURL
    }

    func start() {
        guard polling == nil else { return }
        polling = Task { [weak self] in await self?.run() }
    }
    func stop() {
        polling?.cancel()
        polling = nil
        session.invalidateAndCancel()
        session = URLSession(configuration: .ephemeral, delegate: redirectPolicy, delegateQueue: nil)
    }

    private func currentIdentity() async -> IosDeviceIdentity? {
        try? await IosDeviceIdentityKt.currentIosDeviceIdentity()
    }
    private func sameIdentity(_ identity: IosDeviceIdentity) async -> Bool {
        guard let latest = await currentIdentity() else { return false }
        return latest.subject == identity.subject && latest.deviceId == identity.deviceId && latest.token == identity.token
    }

    private func run() async {
        // A result whose POST lost its response is retried, never re-executed in the store.
        var pending: (RetailDeviceCommand, [String: Any], IosDeviceIdentity)?
        while !Task.isCancelled, let owner, owner.enabled, owner.foreground {
            if let identity = await currentIdentity(), !Task.isCancelled {
                do {
                    if let queued = pending {
                        let identityStillCurrent = await sameIdentity(queued.2)
                        if queued.0.expiresAt.map({ $0 <= Date() }) == true || !identityStillCurrent {
                            pending = nil
                        } else {
                            _ = try await request("v1/device/results", identity: queued.2,
                                body: ["device_id": queued.2.deviceId, "id": queued.0.id, "result": queued.1])
                            pending = nil
                        }
                    } else {
                        let reply = try await request("v1/device/commands?device_id=\(identity.deviceId)", identity: identity)
                        if let raw = reply["command"] as? [String: Any], let id = raw["id"] as? String,
                           UUID(uuidString: id) != nil, !Task.isCancelled, await sameIdentity(identity) {
                            let command = RetailDeviceCommand(raw, remote: true)
                            let result = if let command { await owner.execute(command) }
                                else { PerekrestokDeviceMCP.failure("invalid_arguments") }
                            guard !Task.isCancelled, owner.enabled, owner.foreground else { break }
                            guard await sameIdentity(identity) else { pending = nil; continue }
                            if let command, command.expiresAt.map({ $0 > Date() }) == true {
                                pending = (command, result, identity)
                            } else if command == nil {
                                _ = try await request("v1/device/results", identity: identity,
                                    body: ["device_id": identity.deviceId, "id": id, "result": result])
                            }
                        }
                    }
                } catch BridgeError.unauthorized {
                    if await sameIdentity(identity) { try? await IosDeviceIdentityKt.expireIosDeviceIdentity(subject: identity.subject, token: identity.token) }
                    pending = nil
                } catch BridgeError.expired {
                    pending = nil
                } catch { /* Offline/retry on next foreground poll. Never log authorization or page data. */ }
            }
            try? await Task.sleep(for: .milliseconds(700))
        }
    }

    private func request(_ path: String, identity: IosDeviceIdentity, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard !Task.isCancelled, let owner, owner.enabled, owner.foreground,
              let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else { throw CancellationError() }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue("Bearer \(identity.token)", forHTTPHeaderField: "Authorization")
        request.setValue(identity.deviceId, forHTTPHeaderField: "X-Device-Id")
        if let body {
            let data = try JSONSerialization.data(withJSONObject: body)
            guard data.count <= 256_000 else { throw BridgeError.invalid }
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
        }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw BridgeError.invalid }
        if response.statusCode == 401 || response.statusCode == 403 { throw BridgeError.unauthorized }
        if response.statusCode == 409 { throw BridgeError.expired }
        guard response.statusCode == 200, data.count <= 65_536,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw BridgeError.invalid }
        return object
    }
    private enum BridgeError: Error { case unauthorized, expired, invalid }
}

private final class RetailNoRedirect: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
