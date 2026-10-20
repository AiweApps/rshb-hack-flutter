import SwiftUI
import UIKit

/// iOS mirror of the Kotlin design system in `:sharedUIKit`
/// (`AppColors.kt`, package `com.aiweapps.winescan.uikit.theme`).
///
/// IMPORTANT — this is a **second, independent copy** of the palette. Compose `Color` values
/// cannot cross the Kotlin/Native bridge into SwiftUI, so every token below is hand-maintained
/// and must be kept in sync by hand whenever `AppColors.kt` changes. If Android and iOS visibly
/// disagree on a colour, this is the file to check first.
///
/// The native palette uses: paper and card surfaces,
/// ink for text, wine for actions, gold for accents. Screens use these for brand-specific
/// surfaces and fall back to the system semantic colours (`.secondary`, `.separator`) where the
/// platform's own look is the point.
enum AppTheme {
    /// Clean sans-serif hierarchy follows the public website; native text remains scalable.
    static let wineTitle = Font.system(.title3).weight(.semibold)
    /// Page background.
    static let paper = Color(light: rgb(0xFFFFFF), dark: rgb(0x19191B))
    /// Slightly deeper background: sheets, chips, inactive tabs.
    static let paper2 = Color(light: rgb(0xF4F4F6), dark: rgb(0x2B2A2E))
    /// Surface of cards and dialogs.
    static let card = Color(light: rgb(0xFFFFFF), dark: rgb(0x232326))
    /// Rows of an inset grouped list. The system's own cell colour, pinned: inside a sheet the
    /// default changes with the sheet's height (see-through on the glass of a half sheet,
    /// opaque at full height). iOS-only, no Kotlin counterpart.
    static let groupedRow = Color(uiColor: .secondarySystemGroupedBackground)
    /// Background of an inset grouped list at full height, behind `groupedRow`. iOS-only.
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    /// Primary text.
    static let ink = Color(light: rgb(0x141217), dark: rgb(0xF4F2F4))
    /// Secondary text.
    static let ink2 = Color(light: rgb(0x3B3840), dark: rgb(0xC9C4CA))
    /// Captions, hints, placeholders.
    static let muted = Color(light: rgb(0x6B6770), dark: rgb(0xADA6AE))
    /// Hairlines, borders.
    static let rule = Color(light: rgb(0xE7E7E9), dark: rgb(0x3C393F))
    /// Brand colour: primary buttons, links, active state.
    static let wine = Color(light: rgb(0x6B1736), dark: rgb(0xF08A9E))
    /// Pressed / hovered brand colour.
    static let wine2 = Color(light: rgb(0x561129), dark: rgb(0xF5A4B4))
    /// Text and icons on a wine-filled surface.
    static let onWine = Color(light: rgb(0xFFFFFF), dark: rgb(0x21181D))
    /// Accent: focus rings, selected frame, step numerals.
    static let gold = Color(light: rgb(0xA9853F), dark: rgb(0xD0AB62))
    /// Service is ready.
    static let ok = Color(light: rgb(0x3F6B3A), dark: rgb(0x8FBF83))
    /// Service is busy; warnings.
    static let warn = Color(light: rgb(0x9A6516), dark: rgb(0xE0A64A))
    /// Errors; service down.
    static let bad = Color(light: rgb(0x9B2B2B), dark: rgb(0xEC8B84))
    /// Badges drawn over a photo: white on any theme.
    static let onPhoto = Color.white
    /// Scrim over a photo (draw mode, viewer).
    static let scrim = Color(light: rgb(0x26181A), dark: rgb(0x000000))

    /// Wine in the shutter bottle while the service has a queue. iOS-only drawing detail (the
    /// bottle sits on a white disc), so it has no counterpart in `AppColors.kt`.
    static let bottleLiquidBusy = Color(light: rgb(0xA8443A), dark: rgb(0xA8443A))
    /// Paper label on the shutter bottle; the same in both schemes, like the white disc.
    static let bottleLabel = Color(light: rgb(0xEFE6D4), dark: rgb(0xEFE6D4))

    private static func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private extension Color {
    /// A dynamic colour that resolves to `light` or `dark` based on the current trait
    /// collection, mirroring how the Kotlin side picks `LightAppColors`/`DarkAppColors`.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
