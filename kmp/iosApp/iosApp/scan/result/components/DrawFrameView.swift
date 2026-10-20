import SwiftUI
import SharedLogic

/// Draw the frame of one bottle on the photo, full screen: drag outside the frame to draw a
/// new one, inside to move it, from a corner to resize. The drawn frame is adjustable at once.
/// Boxes are kept in frame pixels throughout.
///
/// Full screen on purpose: drawing is a drag, and a sheet's pull-down recognizer would take it.
struct DrawFrameView: View {
    @ObservedObject private var observableState: ObservableValue<DrawFrameState>
    private let component: DrawFrameComponent

    @State private var image: UIImage?
    @State private var imageLoaded = false
    @State private var live: FrameRect?
    @State private var drag: DraftDrag?
    @State private var isAtEdge = false
    @State private var drawStartCount = 0
    @State private var settleCount = 0
    @State private var scanCount = 0

    init(component: DrawFrameComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
    }

    var body: some View {
        let committed = observableState.value.draft.map(FrameRect.init)
        let draft = live ?? committed

        VStack(spacing: 0) {
            topBar
            stage(draft: draft, committed: committed)
            bottomBar(hasDraft: committed != nil && image != nil)
        }
        .background(AppTheme.scrim.ignoresSafeArea())
        // The photo is a dark room whatever the app theme is: glass and the bars take their
        // light-on-dark look from this.
        .preferredColorScheme(.dark)
        .task(id: component.photoPath) {
            image = await LocalPhotoLoader.image(path: component.photoPath, maxPixel: nil)
            imageLoaded = true
            if let image, let pixels = orientedPixelSize(image) {
                component.onImageSizeResolved(width: Int32(pixels.width), height: Int32(pixels.height))
            }
        }
        // The committed draft has caught up with the finger's frame: the local copy can go.
        .onChange(of: committed) { _, _ in
            if drag == nil { live = nil }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: drawStartCount)
        .sensoryFeedback(.selection, trigger: settleCount)
        .sensoryFeedback(trigger: isAtEdge) { _, atEdge in atEdge ? .selection : nil }
        .sensoryFeedback(.impact(weight: .medium), trigger: scanCount)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            CloseButton(action: component.onCancelClicked)
                .tint(AppTheme.onPhoto)

            Text(String(localized: "frame_hint"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.onPhoto)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .appGlass(in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func stage(draft: FrameRect?, committed: FrameRect?) -> some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .accessibilityHidden(true)
                } else if !imageLoaded {
                    ProgressView().tint(AppTheme.onPhoto)
                } else {
                    Text(String(localized: "scan_error_photo_open"))
                        .foregroundStyle(AppTheme.onPhoto)
                }
                if image != nil, let geometry = geometry(in: proxy.size) {
                    BottleOverlayCanvas(geometry: geometry, view: component.view, draft: draft)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(geometry: geometry, committed: committed))
                }
            }
        }
        // Room for the corner handles at the edge of the photo, which the canvas would clip.
        .padding(12)
    }

    private func bottomBar(hasDraft: Bool) -> some View {
        Button {
            scanCount += 1
            component.onScanClicked()
        } label: {
            Label(String(localized: "frame_scan"), appSymbol: "viewfinder")
                .font(.headline)
                // Dark text on the light wine of the dark scheme; white would not read.
                // Disabled, the fill turns dark grey, so the label goes light.
                .foregroundStyle(hasDraft ? AppTheme.onWine : AppTheme.onPhoto.opacity(0.6))
                .frame(maxWidth: .infinity)
        }
        .appPrimaryButtonStyle()
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(!hasDraft)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    /// The frame size the boxes refer to: the answer's, or the decoded image until there is one.
    private func geometry(in size: CGSize) -> PhotoGeometry? {
        var frame: CGSize?
        if let pair = component.frame, pair.count == 2, pair[0].intValue > 0, pair[1].intValue > 0 {
            frame = CGSize(width: CGFloat(pair[0].intValue), height: CGFloat(pair[1].intValue))
        } else if let image {
            // Pixels as the photo is shown, EXIF rotation included.
            frame = orientedPixelSize(image)
        }
        guard let frame, frame.width > 0, frame.height > 0, size.width > 0, size.height > 0 else { return nil }
        return PhotoGeometry(box: size, frame: frame)
    }

    private func orientedPixelSize(_ image: UIImage) -> CGSize? {
        guard let pixels = image.cgImage else { return nil }
        switch image.imageOrientation {
        case .left, .right, .leftMirrored, .rightMirrored:
            return CGSize(width: CGFloat(pixels.height), height: CGFloat(pixels.width))
        default:
            return CGSize(width: CGFloat(pixels.width), height: CGFloat(pixels.height))
        }
    }

    private func dragGesture(geometry: PhotoGeometry, committed: FrameRect?) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let mode: DraftDrag
                if let started = drag {
                    mode = started
                } else {
                    mode = DraftDrag.begin(touch: value.startLocation, draft: live ?? committed, geometry: geometry)
                    drag = mode
                    if mode.isDraw { drawStartCount += 1 }
                }
                let minSide = CGFloat(ScanLimits.shared.MIN_ROI_SIDE_WHILE_RESIZING) / geometry.scale
                let result = mode.frame(at: value.location, geometry: geometry, minSide: minSide)
                live = result
                isAtEdge = result.touchesEdge(of: geometry.frame)
            }
            .onEnded { _ in
                finish(geometry: geometry)
            }
    }

    private func finish(geometry: PhotoGeometry) {
        defer {
            drag = nil
            isAtEdge = false
        }
        guard let result = live, let mode = drag else {
            live = nil
            return
        }
        if mode.isDraw {
            // A stray touch is not a frame: too small a box changes nothing.
            let minSide = CGFloat(ScanLimits.shared.MIN_ROI_SIDE_ON_SCREEN) / geometry.scale
            guard result.width >= minSide, result.height >= minSide else {
                live = nil
                return
            }
        }
        settleCount += 1
        // `live` stays until the committed draft comes back from the component (see the
        // `onChange` on the draft): the state is published a frame later, and dropping `live`
        // now would flash the previous frame for that frame.
        component.onDraftChanged(box: result.bottleBox)
    }
}
