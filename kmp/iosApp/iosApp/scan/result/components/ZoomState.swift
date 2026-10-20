import SwiftUI
import SharedLogic

/// Zoom and pan shared by every layer that must move together: pinch up to
/// `COMPARE_MAX_ZOOM`, drag to pan while zoomed, double tap to reset.
struct ZoomState: Equatable {
    private(set) var scale: CGFloat = 1
    private(set) var offset: CGSize = .zero
    private var committedScale: CGFloat = 1
    private var committedOffset: CGSize = .zero

    var isZoomed: Bool { scale > 1 }

    private static var maxZoom: CGFloat { CGFloat(ScanLimits.shared.COMPARE_MAX_ZOOM) }

    mutating func magnify(by magnification: CGFloat, in size: CGSize) {
        scale = min(max(committedScale * magnification, 1), Self.maxZoom)
        offset = Self.clamp(offset, scale: scale, size: size)
    }

    mutating func endMagnify() {
        committedScale = scale
        if scale <= 1 { reset() } else { committedOffset = offset }
    }

    mutating func pan(by translation: CGSize, in size: CGSize) {
        guard scale > 1 else { return }
        offset = Self.clamp(
            CGSize(width: committedOffset.width + translation.width, height: committedOffset.height + translation.height),
            scale: scale,
            size: size
        )
    }

    mutating func endPan() {
        committedOffset = offset
    }

    mutating func reset() {
        self = ZoomState()
    }

    /// Keeps the zoomed content from being dragged off the frame.
    private static func clamp(_ offset: CGSize, scale: CGFloat, size: CGSize) -> CGSize {
        let limitX = size.width * (scale - 1) / 2
        let limitY = size.height * (scale - 1) / 2
        return CGSize(
            width: min(max(offset.width, -limitX), limitX),
            height: min(max(offset.height, -limitY), limitY)
        )
    }
}

extension View {

    /// Draws the view with the shared zoom applied.
    func zoomed(_ state: ZoomState) -> some View {
        scaleEffect(state.scale).offset(state.offset)
    }

    /// Pinch, pan and double tap on `state`, for a frame of `size`.
    func zoomGestures(_ state: Binding<ZoomState>, size: CGSize) -> some View {
        gesture(
            MagnifyGesture()
                .onChanged { state.wrappedValue.magnify(by: $0.magnification, in: size) }
                .onEnded { _ in state.wrappedValue.endMagnify() }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { state.wrappedValue.pan(by: $0.translation, in: size) }
                .onEnded { _ in state.wrappedValue.endPan() }
        )
        .onTapGesture(count: 2) {
            withAnimation(.spring(duration: 0.3)) { state.wrappedValue.reset() }
        }
    }
}
