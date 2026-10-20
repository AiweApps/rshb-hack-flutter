import SwiftUI

/// The vertical line of the reveal viewer with its round glass handle. The whole 44 pt strip
/// around the line takes the drag; `onDrag` gets the finger's x in the viewer's space.
struct RevealDivider: View {
    let height: CGFloat
    let width: CGFloat
    let reveal: CGFloat
    let onChanged: (CGFloat) -> Void
    let onEnded: () -> Void

    static let space = "reveal"
    private static let handleSize: CGFloat = 44

    @State private var grabOffset: CGFloat?

    var body: some View {
        let x = width * reveal
        let handleX = min(max(x, Self.handleSize / 2), width - Self.handleSize / 2)

        ZStack {
            Rectangle()
                .fill(AppTheme.onPhoto)
                .frame(width: 3, height: height)
                .shadow(color: AppTheme.scrim.opacity(0.5), radius: 4)
                .position(x: x, y: height / 2)
            AppIcon(systemName: "arrow.left.and.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.wine)
                .frame(width: Self.handleSize, height: Self.handleSize)
                .appGlass(in: Circle())
                .position(x: handleX, y: height / 2)
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
        .overlay {
            Color.clear
                .frame(width: Self.handleSize, height: height)
                .contentShape(Rectangle())
                .position(x: handleX, y: height / 2)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                        .onChanged { value in
                            let offset = grabOffset ?? (x - value.location.x)
                            grabOffset = offset
                            onChanged(value.location.x + offset)
                        }
                        .onEnded { _ in
                            grabOffset = nil
                            onEnded()
                        }
                )
                .accessibilityLabel(String(localized: "reveal_handle"))
                .accessibilityValue("\(Int(reveal * 100))%")
                .accessibilityAdjustableAction { direction in
                    let step: CGFloat = 0.1
                    onChanged(width * (reveal + (direction == .increment ? step : -step)))
                    onEnded()
                }
        }
    }
}
