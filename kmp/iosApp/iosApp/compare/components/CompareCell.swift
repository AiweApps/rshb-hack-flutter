import SwiftUI
import SharedLogic

/// The row names of the comparison table.
enum CompareAttributeLabel {
    static func text(for attribute: CompareAttribute) -> String {
        if attribute == CompareAttribute.color { return String(localized: "compare_attr_color") }
        if attribute == CompareAttribute.sugar { return String(localized: "compare_attr_sugar") }
        if attribute == CompareAttribute.alcohol { return String(localized: "compare_attr_alcohol") }
        if attribute == CompareAttribute.grapes { return String(localized: "compare_attr_grapes") }
        if attribute == CompareAttribute.region { return String(localized: "compare_attr_region") }
        if attribute == CompareAttribute.pairings { return String(localized: "compare_attr_pairings") }
        return String(localized: "compare_attr_temperature")
    }
}

/// One cell: a value, pairings (the ones every wine lists in the wine colour), a placeholder
/// while the wine's gastronomy loads, or «No data».
struct CompareCell: View {
    let value: CompareValue
    /// Rows where the wines agree are drawn quieter.
    let isQuiet: Bool

    var body: some View {
        content
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var valueStyle: Color {
        isQuiet ? AppTheme.ink2 : AppTheme.ink
    }

    @ViewBuilder
    private var content: some View {
        if let text = value as? CompareValue.Text {
            Text(text.value).foregroundStyle(valueStyle)
        } else if let color = value as? CompareValue.Color {
            localized(GastronomyText.color(color.color, isSparkling: color.isSparkling?.boolValue))
        } else if let sugar = value as? CompareValue.Sugar {
            localized(GastronomyText.sugar(sugar.sugar))
        } else if let temperature = value as? CompareValue.Temperature {
            Text(GastronomyText.temperature(temperature.range)).foregroundStyle(valueStyle)
        } else if let pairings = value as? CompareValue.Pairings {
            if pairings.dishes.isEmpty {
                Text(String(localized: "gastro_none_listed")).foregroundStyle(AppTheme.muted)
            } else {
                Text(pairingsText(pairings)).foregroundStyle(valueStyle)
            }
        } else if value is CompareValue.Pending {
            Text(String(repeating: "x", count: 8)).loadingPlaceholder()
        } else {
            Text(String(localized: "common_no_data")).foregroundStyle(AppTheme.muted)
        }
    }

    @ViewBuilder
    private func localized(_ text: String?) -> some View {
        if let text {
            Text(text).foregroundStyle(valueStyle)
        } else {
            Text(String(localized: "common_no_data")).foregroundStyle(AppTheme.muted)
        }
    }

    private func pairingsText(_ pairings: CompareValue.Pairings) -> AttributedString {
        var result = AttributedString()
        for (index, dish) in pairings.dishes.enumerated() {
            var part = AttributedString(dish.label)
            if pairings.sharedIds.contains(dish.id) {
                part.foregroundColor = AppTheme.wine
                part.font = .subheadline.weight(.semibold)
            }
            result += part
            if index < pairings.dishes.count - 1 {
                result += AttributedString(", ")
            }
        }
        return result
    }
}
