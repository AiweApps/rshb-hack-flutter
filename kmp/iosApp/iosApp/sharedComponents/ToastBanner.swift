import SwiftUI

extension View {

    /// A short banner over the top of the screen for a component's `toast` field. The banner
    /// reports back through `onConsumed` after a few seconds so the component clears it.
    func toastBanner(message: String?, onConsumed: @escaping () -> Void) -> some View {
        overlay(alignment: .top) {
            ToastBanner(message: message, onConsumed: onConsumed)
        }
    }
}

struct ToastBanner: View {
    let message: String?
    let onConsumed: () -> Void

    private static let visibleSeconds: Double = 3

    var body: some View {
        ZStack {
            if let message {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .appGlass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.spring(duration: 0.35), value: message)
        .task(id: message) {
            guard message != nil else { return }
            try? await Task.sleep(for: .seconds(Self.visibleSeconds))
            if !Task.isCancelled {
                onConsumed()
            }
        }
        .allowsHitTesting(false)
    }
}
