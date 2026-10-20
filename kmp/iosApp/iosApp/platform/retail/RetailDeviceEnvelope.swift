import Foundation

/// Whitelist at the page/native boundary. The server independently validates these same bindings.
enum RetailDeviceEnvelope {
    static func validated(_ raw: [String: Any], command: RetailDeviceCommand) -> [String: Any]? {
        guard raw["done"] as? Bool == true, raw["origin"] as? String == PerekrestokDeviceMCP.origin,
              let rows = raw["results"] as? [[String: Any]], rows.count == (command.operation == "select_store" ? 1 : 2),
              let selected = rows.first, selected["operation"] as? String == "select_store",
              RetailDeviceCommand.integer(selected["http_status"]) == 200,
              RetailDeviceCommand.integer(selected["shop_id"]) == command.storeID,
              selected["mode"] as? String == "catalog", let sap = selected["sap_id"] as? String,
              RetailDeviceCommand.validSAP(sap), command.sapID == nil || sap == command.sapID,
              selected["request_method"] as? String == "PUT",
              selected["response_url"] as? String == "\(PerekrestokDeviceMCP.origin)/api/customer/1.4.1.0/delivery/mode/pickup/\(command.storeID)"
        else { return nil }
        var resultRows: [[String: Any]] = [["operation": "select_store", "http_status": 200,
            "shop_id": command.storeID, "sap_id": sap, "mode": "catalog",
            "request_method": "PUT", "response_url": selected["response_url"]!]]
        if command.operation != "select_store" {
            let row = rows[1]
            guard row["operation"] as? String == command.operation,
                  RetailDeviceCommand.integer(row["http_status"]) == 200, row["sap_id"] as? String == sap,
                  let items = row["items"] as? [[String: Any]], items.count <= 48 else { return nil }
            let products = items.compactMap(product)
            guard products.count == items.count else { return nil }
            if command.operation == "get_product" {
                guard products.count == 1, RetailDeviceCommand.integer(products[0]["id"]) == command.productID else { return nil }
                resultRows.append(["operation": command.operation, "http_status": 200, "sap_id": sap,
                                   "store_binding": "session_context", "item": products[0]])
            } else {
                resultRows.append(["operation": command.operation, "http_status": 200, "sap_id": sap,
                                   "store_verified": true, "items": products])
            }
        }
        return ["done": true, "store": ["id": command.storeID, "sap_id": sap, "mode": "catalog"],
            "results": resultRows, "origin": PerekrestokDeviceMCP.origin,
            "source": "perekrestok_webview", "captured_at_ms": Int64(Date().timeIntervalSince1970 * 1000),
            "provenance": ["platform": "ios", "adapter": "wkwebview", "transport": "https_device_poll", "contract_version": 1]]
    }

    private static func product(_ row: [String: Any]) -> [String: Any]? {
        guard let id = RetailDeviceCommand.integer(row["id"]), id > 0,
              let title = row["title"] as? String, !title.isEmpty, title.count <= 2000 else { return nil }
        var output: [String: Any] = ["id": id, "title": title]
        for key in ["price_kopeks", "primary_category_id", "catalog_primary_category_id", "unit", "price_per_quantum_kopeks"] {
            output[key] = RetailDeviceCommand.integer(row[key]).flatMap { $0 >= 0 ? $0 : nil } ?? NSNull()
        }
        for key in ["quantum", "quantum_step", "weight", "volume"] {
            if let number = row[key] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite,
               number.doubleValue >= 0 { output[key] = number }
            else { output[key] = NSNull() }
        }
        for key in ["slug", "plu", "unit_name", "balance_state"] {
            output[key] = (row[key] as? String).map { String($0.prefix(500)) } ?? NSNull()
        }
        for key in ["url", "image_url"] {
            if let value = row[key] as? String, value.count <= 2000, let url = URL(string: value),
               url.scheme == "https", url.user == nil, url.password == nil, url.port == nil,
               (key == "url" && url.host == "www.perekrestok.ru" && url.path.hasPrefix("/cat/")) ||
                (key == "image_url" && url.host == "tsx.x5static.net" && url.path.hasPrefix("/i/200x200-fit/xdelivery/files/")) {
                output[key] = value
            } else { output[key] = NSNull() }
        }
        return output
    }
}
