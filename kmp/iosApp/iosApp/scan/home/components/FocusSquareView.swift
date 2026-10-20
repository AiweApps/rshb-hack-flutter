import SwiftUI

/// Where the viewfinder was last tapped to focus; `id` tells one tap from the next.
struct FocusMark: Equatable {
    let id: Int
    let point: CGPoint
}

/// The small gold square that lands on the tapped point, settles and fades out. Laid over
/// the viewfinder, in the same coordinates as the tap.
struct FocusSquareView: View {
    @Binding var mark: FocusMark?

    private static let side: CGFloat = 72
    private static let visibleSeconds: Double = 1.2

    var body: some View {
        ZStack {
            if let mark {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.gold, lineWidth: 1.5)
                    .frame(width: Self.side, height: Self.side)
                    .position(mark.point)
                    .transition(.scale(scale: 1.4).combined(with: .opacity))
                    .id(mark.id)
            }
        }
        .animation(.spring(duration: 0.3), value: mark?.id)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: mark?.id) {
            guard let id = mark?.id else { return }
            try? await Task.sleep(for: .seconds(Self.visibleSeconds))
            if !Task.isCancelled, mark?.id == id {
                mark = nil
            }
        }
    }
}
