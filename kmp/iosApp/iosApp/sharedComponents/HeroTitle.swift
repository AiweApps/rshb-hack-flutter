import SwiftUI

/// The 30 pt bold title that leads a screen's content (wine name, «What's on the table?»),
/// scaled with Dynamic Type.
struct HeroTitle: View {
    let text: String

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 30

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}
