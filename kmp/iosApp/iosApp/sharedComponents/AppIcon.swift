import SwiftUI
import UIKit

/// Semantic aliases keep native controls and accessibility labels independent of asset names.
/// Unprovided system actions (permissions, downloads, recording waveform) retain SF Symbols.
enum AppIconCatalog {
    static let symbols: [String: String] = [
        "house": "home", "clock.arrow.circlepath": "history", "clock": "history",
        "heart": "favorite", "heart.fill": "favorite", "person": "account", "person.crop.circle": "account",
        "camera": "camera", "camera.viewfinder": "camera", "viewfinder": "camera", "crop": "camera",
        "magnifyingglass": "search", "mappin.and.ellipse": "location", "mappin": "location", "location": "location",
        "bolt": "flash", "bolt.fill": "flash", "bolt.slash": "flashoff",
        "slider.horizontal.3": "filter", "arrow.left": "back", "arrow.right": "forward",
        "xmark": "close", "arrow.up.right": "external", "plus": "add", "minus": "remove",
        "star": "star", "wineglass": "wine", "waterbottle": "bottle",
        "bubble.left": "chat", "bubble.left.and.bubble.right": "chat", "sparkles": "chat",
        "rectangle.split.2x1": "compare", "square.split.2x1": "compare",
        "arrow.left.arrow.right": "compare", "arrow.left.arrow.right.circle": "compare", "arrow.left.arrow.right.circle.fill": "compare",
        "line.3.horizontal": "menu", "square.and.pencil": "newchat", "mic": "mic",
        "paperplane": "send", "paperplane.fill": "send", "arrow.up": "arrowup",
        "checkmark": "check", "checkmark.circle": "check", "checkmark.circle.fill": "check",
        "chevron.right": "chevronright", "chevron.down": "chevrondown", "chevron.up": "chevronup", "chevron.left": "chevronleft",
        "photo": "photos", "photo.on.rectangle": "photos", "photo.on.rectangle.angled": "photos",
        "fork.knife": "dinner", "basket": "store", "storefront": "store", "bag": "store", "gearshape": "settings",
        "arrow.up.left.and.arrow.down.right": "expand", "ellipsis": "more", "ellipsis.circle": "more", "plus.circle": "pluscircle",
        "cloud": "cloud", "trash": "delete", "exclamationmark.circle": "error", "info.circle": "info", "globe": "language",
        "square.and.arrow.up": "share", "chevron.up.chevron.down": "unfold", "crown.fill": "crown",
    ]
    static let mirrored: Set<String> = ["back", "forward", "external", "chevronleft", "chevronright", "newchat"]
    static func asset(for symbol: String) -> String? {
        symbols[symbol].map { "app_icon_" + $0 }
    }
    static func image(for symbol: String) -> UIImage? {
        asset(for: symbol).flatMap { UIImage(named: $0)?.withRenderingMode(.alwaysTemplate) }
    }
}

struct AppIcon: View {
    let systemName: String
    @ScaledMetric private var size: CGFloat
    @Environment(\.layoutDirection) private var direction

    init(systemName: String, size: CGFloat = 24) {
        self.systemName = systemName
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        if let asset = AppIconCatalog.asset(for: systemName) {
            Image(asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .scaleEffect(x: direction == .rightToLeft && AppIconCatalog.mirrored.contains(AppIconCatalog.symbols[systemName] ?? "") ? -1 : 1, y: 1)
                .accessibilityHidden(true)
        } else {
            Image(systemName: systemName)
        }
    }
}

extension Label where Title == Text, Icon == AppIcon {
    @MainActor
    init<S: StringProtocol>(_ title: S, appSymbol: String, iconSize: CGFloat = 24) {
        self.init { Text(verbatim: String(title)) } icon: { AppIcon(systemName: appSymbol, size: iconSize) }
    }

    @MainActor
    init(_ title: LocalizedStringKey, appSymbol: String, iconSize: CGFloat = 24) {
        self.init { Text(title) } icon: { AppIcon(systemName: appSymbol, size: iconSize) }
    }
}
