import SwiftUI
import SharedLogic

/// Real detection evidence for the in-flight photo. Crops use the same original frame as the boxes.
struct ScanGeometryPreview: View {
    let photoPath: String
    let progress: ScanGeometryProgress
    @State private var image: UIImage?

    private var sourceSize: CGSize {
        CGSize(width: CGFloat(progress.frameSize[0].intValue), height: CGFloat(progress.frameSize[1].intValue))
    }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { proxy in
                let geometry = PhotoGeometry(box: proxy.size, frame: sourceSize)
                ZStack {
                    AppTheme.paper2
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Canvas { context, _ in
                        for region in progress.regions {
                            if let bottle = region.bottleBox {
                                outline(geometry.toScreenRect(bottle), color: AppTheme.wine, context: &context)
                            }
                            if let label = region.labelBox {
                                outline(geometry.toScreenRect(label), color: AppTheme.gold, context: &context)
                            }
                            if progress.regions.count > 1, let box = region.bottleBox ?? region.labelBox {
                                let rect = geometry.toScreenRect(box)
                                let center = CGPoint(x: rect.minX + 13, y: rect.minY + 13)
                                context.fill(Path(ellipseIn: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)),
                                             with: .color(AppTheme.wine))
                                context.draw(Text("\(region.number)").font(.caption2.bold()).foregroundColor(AppTheme.onWine), at: center)
                            }
                        }
                    }.allowsHitTesting(false)
                }
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityLabel(String(localized: "scan_preview_photo"))

            if progress.regions.count == 1, let region = progress.regions.first {
                crops(region)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(progress.regions, id: \.id) { region in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.format("scan_preview_region", region.number)).font(.caption.weight(.semibold))
                                crops(region)
                            }.frame(width: 260)
                        }
                    }
                }
            }
        }
        .task(id: photoPath) {
            image = nil
            let loaded = await LocalPhotoLoader.image(path: photoPath, maxPixel: 1600)
            guard !Task.isCancelled else { return }
            image = loaded
        }
    }

    private func outline(_ rect: CGRect, color: Color, context: inout GraphicsContext) {
        let path = Path(roundedRect: rect, cornerRadius: 4)
        context.stroke(path, with: .color(AppTheme.onPhoto.opacity(0.9)), lineWidth: 4)
        context.stroke(path, with: .color(color), lineWidth: 2)
    }

    private func crops(_ region: ScanDetectedRegion) -> some View {
        HStack(alignment: .top, spacing: 12) {
            crop(region.bottleBox, title: String(localized: "scan_preview_bottle"), color: AppTheme.wine)
            crop(region.labelBox, title: String(localized: "scan_preview_label"), color: AppTheme.gold)
        }
    }

    private func crop(_ box: BottleBox?, title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(title).font(.caption.weight(.semibold))
            }
            ZStack {
                AppTheme.paper2
                if let image, let box,
                   let cropped = PhotoCrop.crop(image: image, box: box, frame: progress.frameSize, paddingFactor: 0) {
                    Image(uiImage: cropped).resizable().scaledToFit()
                } else {
                    Text(String(localized: box == nil ? "scan_preview_searching" : "scan_preview_loading"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
