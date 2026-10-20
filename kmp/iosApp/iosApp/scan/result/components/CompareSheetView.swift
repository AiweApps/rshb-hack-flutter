import SwiftUI
import SharedLogic

/// The photo crop over the catalogue reference in one frame: drag the divider or use the
/// segments to reveal one or the other, pinch to zoom both.
struct CompareSheetView: View {
    private let component: CompareComponent

    @State private var cropped: UIImage?
    @State private var isCropMissing = false

    init(component: CompareComponent) {
        self.component = component
    }

    var body: some View {
        NavigationStack {
            RevealCompareViewer(
                cropped: cropped,
                isCropMissing: isCropMissing,
                referenceUrl: component.referenceUrl,
                referenceAccess: component.referenceAccess
            )
            .background(AppTheme.scrim.ignoresSafeArea())
            .navigationTitle(String(localized: "result_compare_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton(isInToolbar: true, action: component.onCloseClicked)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await loadCrop() }
    }

    private func loadCrop() async {
        let crop = component.crop, frame = component.frame
        guard let image = await LocalPhotoLoader.image(path: component.photoPath, maxPixel: crop == nil ? 2000 : nil) else {
            guard !Task.isCancelled else { return }
            isCropMissing = true
            return
        }
        guard !Task.isCancelled else { return }
        let result: UIImage
        if let crop {
            result = await Task.detached { PhotoCrop.crop(image: image, box: crop, frame: frame) ?? image }.value
        } else {
            result = image
        }
        guard !Task.isCancelled else { return }
        cropped = result
        isCropMissing = false
    }
}
