import Foundation
import SharedLogic

/// Native SDK conversion only; shared chat still owns confirmation and catalogue readiness.
final class AppleRetailGateway: RetailGateway {
    private let session: PerekrestokDeviceMCP
    private var stores: [Int: AssistantStore] = [:]
    init(session: PerekrestokDeviceMCP) { self.session = session }

    func configureStore(store: AssistantStore) {
        guard store.chain == "perekrestok" else { return }
        stores[Int(store.id)] = store
    }
    func selectStore(storeId: Int32, completionHandler: @escaping (RetailResult?, Error?) -> Void) {
        perform(operation: "select_store", storeID: Int(storeId), query: nil, completion: completionHandler)
    }
    func searchProducts(query: String, storeId: Int32, completionHandler: @escaping (RetailResult?, Error?) -> Void) {
        perform(operation: "search_products", storeID: Int(storeId), query: query, completion: completionHandler)
    }
    private func perform(operation: String, storeID: Int, query: String?, completion: @escaping (RetailResult?, Error?) -> Void) {
        Task { @MainActor in
            guard let store = stores[storeID], session.supported, session.enabled else {
                completion(RetailResultUnavailable(reason: .deviceOffline), nil); return
            }
            var input: [String: Any] = ["id": UUID().uuidString, "operation": operation, "store_id": storeID]
            if let sap = store.sapId { input["sap_id"] = sap }
            if let query { input["query"] = query; input["page"] = 1 }
            guard let command = RetailDeviceCommand(input, remote: false) else {
                completion(RetailResultUnavailable(reason: .storeMismatch), nil); return
            }
            guard let identity = try? await IosDeviceIdentityKt.currentIosDeviceIdentity() else {
                completion(RetailResultUnavailable(reason: .deviceOffline), nil); return
            }
            let raw = await session.execute(command)
            guard let current = try? await IosDeviceIdentityKt.currentIosDeviceIdentity(),
                  current.subject == identity.subject, current.token == identity.token else {
                completion(RetailResultUnavailable(reason: .deviceOffline), nil); return
            }
            if let error = raw["error"] as? String {
                let reason: RetailUnavailableReason
                switch error {
                case "challenge_or_block", "retailer_session_not_ready": reason = .accessRequired
                case "device_offline": reason = .deviceOffline
                case "device_busy": reason = .busy
                case "store_mismatch": reason = .storeMismatch
                default: reason = .other
                }
                completion(RetailResultUnavailable(reason: reason), nil); return
            }
            guard let selected = raw["store"] as? [String: Any], let sap = selected["sap_id"] as? String,
                  RetailDeviceCommand.integer(selected["id"]) == storeID else {
                completion(RetailResultUnavailable(reason: .storeMismatch), nil); return
            }
            let rows = raw["results"] as? [[String: Any]] ?? []
            let items = rows.last?["items"] as? [[String: Any]] ?? []
            let verified = operation == "search_products" && !items.isEmpty
            let resolved = AssistantStore(id: store.id, name: store.name, address: store.address, mode: "catalog",
                checkedAt: verified ? ISO8601DateFormatter().string(from: Date()) : nil, sapId: sap,
                latitude: store.latitude, longitude: store.longitude, distanceMetres: store.distanceMetres,
                chain: store.chain, sourceUrl: store.sourceUrl, updatedAt: store.updatedAt, selectedAt: store.selectedAt)
            stores[storeID] = resolved
            completion(RetailResultSuccess(store: resolved, products: items.compactMap(Self.product), storeVerified: verified), nil)
        }
    }

    private static func product(_ row: [String: Any]) -> AssistantProduct? {
        guard let id = RetailDeviceCommand.integer(row["id"]), let title = row["title"] as? String else { return nil }
        func integer(_ key: String) -> KotlinInt? { RetailDeviceCommand.integer(row[key]).flatMap(Int32.init(exactly:)).map { KotlinInt(int: $0) } }
        func long(_ key: String) -> KotlinLong? { RetailDeviceCommand.integer(row[key]).map { KotlinLong(longLong: Int64($0)) } }
        func double(_ key: String) -> KotlinDouble? { (row[key] as? NSNumber).map { KotlinDouble(double: $0.doubleValue) } }
        return AssistantProduct(id: String(id), title: title, pack: row["unit_name"] as? String, quantity: 1,
            unitPriceKopeks: long("price_kopeks"), lineTotalKopeks: nil, url: row["url"] as? String,
            availability: row["balance_state"] as? String, source: "perekrestok_webview", recipeQuantity: nil,
            retailSlug: row["slug"] as? String, retailPlu: row["plu"] as? String,
            primaryCategoryId: integer("primary_category_id"), catalogPrimaryCategoryId: integer("catalog_primary_category_id"),
            retailUnit: integer("unit"), quantum: double("quantum"), quantumStep: double("quantum_step"),
            weight: double("weight"), volume: double("volume"), pricePerQuantumKopeks: long("price_per_quantum_kopeks"),
            priceBasis: "unknown", purchaseLotQuantity: nil, purchaseLotUnit: nil, purchaseLotPriceKopeks: nil,
            imageUrl: row["image_url"] as? String)
    }
}
