import SwiftUI

extension View {

    /// Sizes the sheet this view is presented in to the view's own height, so a short sheet
    /// has no empty area under its content.
    ///
    /// The wanted height comes from a hidden copy of the content laid out at its ideal height
    /// (a `ScrollView` is as tall as what it holds there). The detent is then corrected until
    /// the room the sheet gives equals that ideal height: how much the system adds around a
    /// detent (safe areas, the floating inset of iOS 26) differs between versions, so it is
    /// measured rather than assumed. There is no larger size to pull the sheet up to: it would
    /// only add empty space. Content taller than the screen stops at the system's largest sheet
    /// and scrolls inside its own `ScrollView`.
    ///
    /// Once the sheet has settled, the content never gets less than the room it settled at.
    /// Pulling a sheet down shrinks the room it offers, and without that floor the text would
    /// re-wrap and truncate under the finger instead of the sheet sliding away whole.
    ///
    /// `fullHeightBackground`, for a sheet that otherwise keeps the system glass: once the
    /// content outgrows the screen the sheet stands at full height, where the system draws it
    /// opaque, and this colour goes behind it there instead of the system one.
    func fittedSheet(fullHeightBackground: Color? = nil) -> some View {
        modifier(FittedSheetModifier(fullHeightBackground: fullHeightBackground))
    }
}

private struct FittedSheetModifier: ViewModifier {
    /// How long the room has to stay put before the sheet counts as settled. Covers the
    /// couple of layout passes a detent change takes, well under the time to start a drag.
    private static let settleDelay: Duration = .milliseconds(500)

    let fullHeightBackground: Color?

    /// A guess for the first frame, corrected as soon as the content has been measured.
    @State private var detentHeight: CGFloat = 300
    @State private var idealHeight: CGFloat = 0
    /// The room the sheet gives at the fitted detent. Only updated while settling, so the
    /// shrinking room of a drag is never taken for it.
    @State private var settledRoom: CGFloat = 0
    @State private var isSettling = true
    /// The content is taller than the sheet can get, so the sheet stands at full height.
    @State private var isOverflowing = false
    @State private var settleTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { room in
                guard isSettling else { return }
                settledRoom = room
                fit()
            }
            .overlay(alignment: .top) {
                content
                    .frame(
                        maxWidth: .infinity,
                        minHeight: settledRoom,
                        maxHeight: .infinity,
                        alignment: .top
                    )
            }
            .background(alignment: .top) {
                content
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { ideal in
                        guard abs(ideal - idealHeight) > 0.5 else { return }
                        idealHeight = ideal
                        beginSettling()
                        fit()
                    }
                    .hidden()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .presentationDetents([.height(detentHeight)])
            .modifier(FullHeightBackground(color: fullHeightBackground, isFullHeight: isOverflowing))
            .onAppear { beginSettling() }
            .onDisappear { settleTask?.cancel() }
    }

    /// Moves the detent by what the content still lacks (or has too much of).
    private func fit() {
        guard idealHeight > 0, settledRoom > 0 else { return }
        let gap = idealHeight - settledRoom
        if abs(gap) > 0.5 {
            detentHeight += gap
            beginSettling()
        }
    }

    /// Lets room changes count for a short while; a detent change is followed by a new room
    /// within a layout pass or two, a user's drag comes much later.
    private func beginSettling() {
        isSettling = true
        settleTask?.cancel()
        settleTask = Task { @MainActor in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled else { return }
            isSettling = false
            isOverflowing = idealHeight > settledRoom + 1
        }
    }
}

/// The opaque background of a sheet standing at full height; nothing at all when no colour
/// is given, so sheets that set their own `presentationBackground` keep it.
private struct FullHeightBackground: ViewModifier {
    let color: Color?
    let isFullHeight: Bool

    func body(content: Content) -> some View {
        if let color {
            content.presentationBackground {
                if isFullHeight {
                    color
                }
            }
        } else {
            content
        }
    }
}
