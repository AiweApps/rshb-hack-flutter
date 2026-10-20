import Foundation
import SharedLogic

/// Names the gastronomy enums and the serving range in the app's language. The shared layer
/// hands over values, never text, so the words live in `Localizable.strings`.
enum GastronomyText {

    /// «Красное» or «Красное, игристое»; a sparkling wine of unknown colour is just «Игристое».
    static func color(_ color: WineColor?, isSparkling: Bool?) -> String? {
        let name = color.flatMap(colorName)
        guard isSparkling == true else { return name }
        guard let name else { return String(localized: "gastro_sparkling") }
        return L10n.format("gastro_color_with_sparkling", name)
    }

    static func sugar(_ sugar: WineSugar?) -> String? {
        guard let sugar else { return nil }
        if sugar == WineSugar.dry { return String(localized: "gastro_sugar_dry") }
        if sugar == WineSugar.semiDry { return String(localized: "gastro_sugar_semi_dry") }
        if sugar == WineSugar.semiSweet { return String(localized: "gastro_sugar_semi_sweet") }
        if sugar == WineSugar.sweet { return String(localized: "gastro_sugar_sweet") }
        if sugar == WineSugar.brut { return String(localized: "gastro_sugar_brut") }
        if sugar == WineSugar.extraBrut { return String(localized: "gastro_sugar_extra_brut") }
        if sugar == WineSugar.brutNature { return String(localized: "gastro_sugar_brut_nature") }
        return nil
    }

    /// «16–18 °C», or «12 °C» when the range is one value.
    static func temperature(_ range: ServingTemperature) -> String {
        if range.minC == range.maxC {
            return L10n.format("gastro_temperature_single", range.minC)
        }
        return L10n.format("gastro_temperature_range", range.minC, range.maxC)
    }

    private static func colorName(_ color: WineColor) -> String? {
        if color == WineColor.red { return String(localized: "gastro_color_red") }
        if color == WineColor.white { return String(localized: "gastro_color_white") }
        if color == WineColor.rose { return String(localized: "gastro_color_rose") }
        if color == WineColor.orange { return String(localized: "gastro_color_orange") }
        return nil
    }
}
