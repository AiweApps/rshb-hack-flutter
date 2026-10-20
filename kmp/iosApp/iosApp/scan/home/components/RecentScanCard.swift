import SwiftUI
import SharedLogic

/// A scan in the collapsed «recent» strip: a square thumbnail with the best match under it.
struct RecentScanCard: View {
    let item: ScanHistoryItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                LocalPhotoView(path: item.photoPath, maxPixel: 320) {
                    Rectangle().fill(AppTheme.paper2)
                }
                .frame(width: Metrics.side, height: Metrics.side)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous))
                .shadow(color: AppTheme.ink.opacity(0.12), radius: 2, y: 1)
                Text(item.bestTitle ?? String(localized: "history_no_match"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink2)
                    .lineLimit(1)
                    .frame(width: Metrics.side, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private enum Metrics {
        static let side: CGFloat = 96
        static let corner: CGFloat = 16
    }
}
