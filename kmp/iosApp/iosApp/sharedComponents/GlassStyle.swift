import SwiftUI

extension View {

    /// Register the floating composer with the native scroll-edge treatment, instead
    /// of painting an opaque strip behind glass. Older iOS keeps the same safe inset.
    @ViewBuilder
    func appBottomControlBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26, *) {
            self.safeAreaBar(edge: .bottom, spacing: 0, content: content)
        } else {
            self.safeAreaInset(edge: .bottom, spacing: 0, content: content)
        }
    }

    /// Content stays on quiet solid surfaces, as on the website. Liquid Glass belongs
    /// to the navigation/control layer, not every card behind it.
    func appMatteCard(cornerRadius: CGFloat = 18) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(AppTheme.card, in: shape)
            .overlay(shape.strokeBorder(AppTheme.rule, lineWidth: 0.5))
            .clipShape(shape)
    }

    /// Liquid Glass surface on iOS 26+, a thin material elsewhere. For custom floating
    /// controls only — system bars and toolbar items are glass on their own.
    ///
    /// `tint` colours the glass (a translucent wash and, before iOS 26, a hairline edge).
    @ViewBuilder
    func appGlass<S: Shape>(in shape: S, interactive: Bool = false, tint: Color? = nil) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = interactive ? .regular.interactive() : .regular
            self.glassEffect(tint.map { base.tint($0.opacity(0.4)) } ?? base, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
                .background {
                    if let tint {
                        shape.fill(tint.opacity(0.26))
                    }
                }
                .overlay {
                    if let tint {
                        shape.stroke(tint.opacity(0.55), lineWidth: 1)
                    }
                }
        }
    }

    /// A round icon button floating over a photo: the glass button style on iOS 26+, a thin
    /// material circle before.
    ///
    /// Not `.glassEffect(.interactive())` on the label of a plain button: the interactive
    /// glass runs its own touch handling, and taps it takes never reach the button's action.
    @ViewBuilder
    func appGlassIconButtonStyle() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass).buttonBorderShape(.circle)
        } else {
            self.buttonStyle(.plain)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    /// Secondary action button: glass on iOS 26+, bordered before.
    @ViewBuilder
    func appSecondaryButtonStyle() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }

    /// Primary action button: tinted glass on iOS 26+, bordered-prominent before.
    @ViewBuilder
    func appPrimaryButtonStyle() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glassProminent).tint(AppTheme.wine)
        } else {
            self.buttonStyle(.borderedProminent).tint(AppTheme.wine)
        }
    }
}

/// Wraps its content in a `GlassEffectContainer` on iOS 26+ so neighbouring glass shapes blend.
struct AppGlassGroup<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing, content: content)
        } else {
            content()
        }
    }
}
