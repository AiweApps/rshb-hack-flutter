import SwiftUI

/// Mirrors `LaunchScreen.storyboard` point for point, so the hand-over from the system launch
/// screen is invisible: the same colour assets, the logo 120 x 120 centred on the whole
/// screen (the storyboard centres it on the view, not on the safe area), and the title 24 pt
/// above the bottom safe area edge.
struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            ZStack {
                // This layer fills the safe area; the shift puts the logo on the centre of
                // the full screen instead.
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .offset(y: (insets.bottom - insets.top) / 2)
                    .accessibilityHidden(true)
                Text(String(localized: "splash_title"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("LaunchText"))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color("LaunchBackground").ignoresSafeArea())
    }
}
