import Foundation

/// Lookup for strings whose key is not known at compile time (a key picked by a state value)
/// and for strings with format arguments. Static keys use `String(localized:)` directly.
enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// `%d` takes `Int32`, `%lld` takes `Int64`, `%@` takes an object — pass matching types.
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), locale: Locale.current, arguments: arguments)
    }

    /// Plural forms live in `Localizable.stringsdict` under the same key.
    static func plural(_ key: String, count: Int32) -> String {
        String.localizedStringWithFormat(NSLocalizedString(key, comment: ""), count)
    }
}
