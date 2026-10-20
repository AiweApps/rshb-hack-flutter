import UIKit

/// Drops the keyboard whoever holds it. A `@FocusState` binding alone does not reach a field
/// hosted in a bottom `safeAreaBar` on iOS 26 reliably, so screens that must close the
/// keyboard (a tap on the content, a menu, a new chat) ask UIKit as well.
enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
