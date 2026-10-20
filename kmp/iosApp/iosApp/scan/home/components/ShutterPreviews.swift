import SwiftUI

#if DEBUG

/// The five moods of the shutter side by side on a dark backdrop, like the viewfinder.
#Preview("Shutter moods") {
    ZStack {
        previewBackdrop
        VStack(spacing: 28) {
            ForEach(ShutterLook.allCases, id: \.self) { look in
                HStack(spacing: 24) {
                    Text(String(describing: look))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 70, alignment: .trailing)
                    BottleShutter(
                        look: look,
                        queueAhead: look == .busy ? 2 : 0,
                        shotCount: 0,
                        refusedTicket: 0,
                        accessibilityValue: ""
                    ) {}
                }
            }
        }
    }
}

/// The hint capsule: the resting text, every status and the queued state.
#Preview("Hint states") {
    ZStack {
        previewBackdrop
        VStack(spacing: 18) {
            StatusHintView(hint: .aim, look: .ready, queueAhead: 0, isShown: true, refusedTicket: 0) {}
            ForEach(ShutterLook.allCases.filter { $0 != .ready }, id: \.self) { look in
                StatusHintView(
                    hint: .status,
                    look: look,
                    queueAhead: look == .busy ? 2 : 0,
                    isShown: true,
                    refusedTicket: 0
                ) {}
            }
            StatusHintView(hint: .queued, look: .busy, queueAhead: 2, isShown: true, refusedTicket: 0) {}
        }
    }
}

/// The whole control row with a mood picker: tap the shutter to pour or to be refused, tap
/// the hint to reveal the status again.
#Preview("Controls, interactive") {
    ShutterPlayground()
}

private var previewBackdrop: some View {
    RadialGradient(
        colors: [Color(white: 0.28), Color(white: 0.08)],
        center: .center,
        startRadius: 20,
        endRadius: 500
    )
    .ignoresSafeArea()
}

private struct ShutterPlayground: View {
    @State private var look = ShutterLook.ready
    @State private var hint = HintKind.aim
    @State private var refusedTicket = 0
    @State private var shotCount = 0
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            previewBackdrop
            ShotFlash(trigger: shotCount)
            VStack {
                Picker("Mood", selection: $look) {
                    ForEach(ShutterLook.allCases, id: \.self) { Text(String(describing: $0)).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()
                Spacer()
                CameraControlsBar(
                    isFlashOn: false,
                    hasFlash: true,
                    isCapturing: false,
                    isBusy: false,
                    look: look,
                    hint: hint,
                    queueAhead: look == .busy ? 2 : 0,
                    isHintShown: hint != .aim || look == .ready,
                    refusedTicket: refusedTicket,
                    shotCount: shotCount,
                    onPickPhoto: {},
                    onShutter: shoot,
                    onFlash: {},
                    onStatusHint: { reveal(.status) }
                )
            }
        }
        .onChange(of: look) { _, new in
            if new == .ready {
                hideTask?.cancel()
                hint = .aim
            } else {
                reveal(.status)
            }
        }
    }

    private func shoot() {
        if look.isRefusing {
            refusedTicket += 1
            reveal(.status)
        } else {
            shotCount += 1
            if look == .busy { reveal(.queued) }
        }
    }

    private func reveal(_ kind: HintKind) {
        hideTask?.cancel()
        hint = kind
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { hint = .aim }
        }
    }
}

#endif
