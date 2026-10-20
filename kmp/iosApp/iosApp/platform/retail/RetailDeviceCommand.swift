import Foundation

/// Fixed operations only. No remotely supplied script, URL, header, or arbitrary store mapping.
struct RetailDeviceCommand {
    let id: String
    let operation: String
    let storeID: Int
    let sapID: String?
    let query: String?
    let page: Int?
    let productID: Int?
    let expiresAt: Date?

    init?(_ value: [String: Any], remote: Bool) {
        let allowed: Set<String> = ["id", "operation", "store_id", "sap_id", "query", "page", "product_id", "expires_at"]
        guard Set(value.keys).isSubset(of: allowed), let id = value["id"] as? String,
              UUID(uuidString: id) != nil, let operation = value["operation"] as? String,
              let store = Self.integer(value["store_id"]), store > 0, store <= Int(Int32.max)
        else { return nil }
        let sap = value["sap_id"] as? String
        if let raw = value["sap_id"], !(raw is NSNull), sap == nil { return nil }
        if let sap, !Self.validSAP(sap) { return nil }
        let expiry = (value["expires_at"] as? String).flatMap(Self.date)
        if remote && expiry == nil { return nil }
        if let expiry, expiry <= Date() { return nil }
        let query = value["query"] as? String
        let page = Self.integer(value["page"])
        let product = Self.integer(value["product_id"])
        switch operation {
        case "select_store":
            guard value["query"] == nil, value["page"] == nil, value["product_id"] == nil else { return nil }
        case "search_products":
            guard let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  query.count <= 100, let page, (1...20).contains(page), sap != nil,
                  value["product_id"] == nil else { return nil }
        case "get_product":
            guard let product, (1...1_000_000_000).contains(product), sap != nil,
                  value["query"] == nil, value["page"] == nil else { return nil }
        default: return nil
        }
        self.id = id; self.operation = operation; self.storeID = store; self.sapID = sap
        self.query = query; self.page = page; self.productID = product; self.expiresAt = expiry
    }

    var scriptArgument: [String: Any] {
        var args: [String: Any] = ["operation": operation, "store_id": storeID]
        if let sapID { args["sap_id"] = sapID }
        if let query { args["query"] = query }
        if let page { args["page"] = page }
        if let productID { args["product_id"] = productID }
        return args
    }

    static func integer(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite, number.doubleValue.rounded() == number.doubleValue,
              abs(number.doubleValue) < 1e12 else { return nil }
        return number.intValue
    }

    static func validSAP(_ value: String) -> Bool {
        (1...12).contains(value.count) && value.utf8.allSatisfy { (48...57).contains($0) } && Int64(value).map { $0 > 0 } == true
    }

    static func date(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
