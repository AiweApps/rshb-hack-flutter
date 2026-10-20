import SwiftUI
import SharedLogic

/// The reveal viewer: the user's bottle over the catalogue reference, one frame, one zoom.
/// `reveal` is the share of the width (from the left) that shows the user's photo; the
/// divider is dragged, or jumps to 100 % / 50 % / 0 % from the segmented control.
struct RevealCompareViewer: View {
    let cropped: UIImage?
    let isCropMissing: Bool
    let referenceUrl: String?
    let referenceAccess: ReferenceAccess?

    @State private var reveal: CGFloat = 0.5
    @State private var zoom = ZoomState()
    @State private var dragStartReveal: CGFloat?
    @State private var isDragging = false
    @State private var snapZone: Int?
    @State private var pickCount = 0

    private static let snapDistance: CGFloat = 0.06
    private static let snapPoints: [CGFloat] = [0, 0.5, 1]

    var body: some View {
        VStack(spacing: 14) {
            viewer
            Text(String(localized: "reveal_hint"))
                .font(.footnote)
                .foregroundStyle(AppTheme.onPhoto.opacity(0.7))
            segments
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .sensoryFeedback(.impact(weight: .light), trigger: isDragging)
        .sensoryFeedback(trigger: snapZone) { _, zone in zone == nil ? nil : .selection }
        .sensoryFeedback(.selection, trigger: pickCount)
    }

    private var viewer: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                ZStack {
                    layer(background: AppTheme.card) { referenceImage }
                    layer(background: AppTheme.paper2) { userImage }
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: size.width * reveal)
                        }
                }
                .frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .zoomGestures($zoom, size: size)
                tags
                RevealDivider(
                    height: size.height,
                    width: size.width,
                    reveal: reveal,
                    onChanged: { drag(to: $0, width: size.width) },
                    onEnded: endDrag
                )
            }
            .frame(width: size.width, height: size.height)
            .coordinateSpace(name: RevealDivider.space)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func layer<Content: View>(background: Color, @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            background
            content().zoomed(zoom)
        }
    }

    private var userImage: some View {
        Group {
            if let cropped {
                Image(uiImage: cropped).resizable().scaledToFit()
            } else if isCropMissing {
                Text(String(localized: "result_photo_missing")).foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
    }

    private var referenceImage: some View {
        AuthorizedAsyncImage(url: referenceUrl, access: referenceAccess) {
            ProgressView()
        } failure: {
            Text(String(localized: "result_reference_missing")).foregroundStyle(.secondary)
        }
    }

    private var tags: some View {
        HStack {
            tag(String(localized: "reveal_mine")).opacity(reveal > 0.15 ? 1 : 0)
            Spacer()
            tag(String(localized: "reveal_reference")).opacity(reveal < 0.85 ? 1 : 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(14)
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.15), value: reveal > 0.15)
        .animation(.easeOut(duration: 0.15), value: reveal < 0.85)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.onPhoto)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(AppTheme.scrim.opacity(0.55), in: Capsule())
    }

    private var segments: some View {
        Picker(String(localized: "result_compare_title"), selection: Binding<Int?>(
            // Any position with both photos on screen reads as «Both», so a dragged
            // divider never leaves the control with nothing selected.
            get: {
                if reveal >= 1 - 0.001 { return 0 }
                if reveal <= 0.001 { return 2 }
                return 1
            },
            set: { pick in
                guard let pick else { return }
                pickCount += 1
                withAnimation(.snappy) { reveal = Self.snapPoints[2 - pick] }
            }
        )) {
            Text(String(localized: "reveal_mine")).tag(Int?.some(0))
            Text(String(localized: "reveal_both")).tag(Int?.some(1))
            Text(String(localized: "reveal_reference")).tag(Int?.some(2))
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        // The viewer is a dark room whatever the app theme is: the inactive segments take
        // their light-on-dark look from this.
        .environment(\.colorScheme, .dark)
    }

    private func drag(to x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        if !isDragging { isDragging = true }
        var next = min(max(x / width, 0), 1)
        var zone: Int?
        for (index, point) in Self.snapPoints.enumerated() where abs(next - point) < Self.snapDistance {
            next = point
            zone = index
        }
        if zone != snapZone { snapZone = zone }
        reveal = next
    }

    private func endDrag() {
        isDragging = false
        snapZone = nil
    }
}
