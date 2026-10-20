import SwiftUI

/// Page indicator: the current page is a longer, wine-coloured capsule.
struct OnboardingPageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { page in
                Capsule()
                    .fill(page == index ? AppTheme.wine : AppTheme.rule)
                    .frame(width: page == index ? 22 : 8, height: 8)
            }
        }
        .animation(.spring(duration: 0.3), value: index)
        .accessibilityHidden(true)
    }
}
