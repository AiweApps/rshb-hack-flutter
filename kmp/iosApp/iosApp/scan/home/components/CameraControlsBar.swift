import SwiftUI

/// The row under the viewfinder: gallery, shutter, flash, with the status hint above. The
/// shutter and the hint carry the service status. Floating controls are Liquid Glass on
/// iOS 26 and thin material before.
struct CameraControlsBar: View {
    let isFlashOn: Bool
    let hasFlash: Bool
    let isCapturing: Bool
    let isBusy: Bool
    let look: ShutterLook
    let hint: HintKind
    let queueAhead: Int
    let isHintShown: Bool
    let refusedTicket: Int
    /// Bumped when a shot was actually taken: the bottle pours.
    let shotCount: Int
    let onPickPhoto: () -> Void
    let onShutter: () -> Void
    let onFlash: () -> Void
    let onStatusHint: () -> Void

    @State private var shutterCount = 0
    @State private var pickCount = 0
    @State private var flashCount = 0

    private static let disabledOpacity = 0.4

    var body: some View {
        VStack(spacing: 18) {
            StatusHintView(
                hint: hint,
                look: look,
                queueAhead: queueAhead,
                isShown: isHintShown,
                refusedTicket: refusedTicket,
                onTap: onStatusHint
            )
            AppGlassGroup(spacing: 24) {
                HStack(spacing: 36) {
                    sideButton(
                        systemImage: "photo.on.rectangle",
                        label: "scan_pick_photo",
                        isEnabled: !isBusy
                    ) {
                        pickCount += 1
                        onPickPhoto()
                    }
                    shutter
                    sideButton(
                        // `bolt.slash` is the off state, `bolt.fill` in gold the armed one.
                        systemImage: isFlashOn ? "bolt.fill" : "bolt.slash",
                        label: "scan_flash",
                        tint: isFlashOn ? AppTheme.gold : AppTheme.onPhoto,
                        isEnabled: !isBusy && hasFlash
                    ) {
                        flashCount += 1
                        onFlash()
                    }
                    .accessibilityAddTraits(isFlashOn ? .isSelected : [])
                }
            }
        }
        .padding(.bottom, 20)
        // The whole strip owns its touches: a tap between the buttons or on the hint must
        // not fall through to the viewfinder underneath and move the focus.
        .frame(maxWidth: .infinity)
        .background(Color.clear.contentShape(Rectangle()).onTapGesture {})
        .sensoryFeedback(.impact(weight: .medium), trigger: shutterCount)
        .sensoryFeedback(.impact(weight: .light), trigger: pickCount)
        .sensoryFeedback(.selection, trigger: flashCount)
        .sensoryFeedback(.warning, trigger: refusedTicket)
    }

    private var shutter: some View {
        BottleShutter(
            look: look,
            queueAhead: queueAhead,
            shotCount: shotCount,
            refusedTicket: refusedTicket,
            accessibilityValue: StatusHintText.status(look: look, hint: .status, queueAhead: queueAhead)
        ) {
            // A refused press answers with the warning haptic instead.
            if !look.isRefusing { shutterCount += 1 }
            onShutter()
        }
        .disabled(isBusy)
        .opacity(isBusy && !isCapturing ? Self.disabledOpacity : 1)
    }

    private func sideButton(
        systemImage: String,
        label: String,
        tint: Color = AppTheme.onPhoto,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AppIcon(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
                // The glass button style pads this out to the 56 pt circles of the plain glass.
                .frame(width: 42, height: 42)
        }
        .appGlassIconButtonStyle()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : Self.disabledOpacity)
        .animation(.snappy, value: isEnabled)
        .accessibilityLabel(L10n.string(label))
    }
}
