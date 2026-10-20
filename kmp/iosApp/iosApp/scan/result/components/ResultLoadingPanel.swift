import SwiftUI
import SharedLogic

/// While the label is read: the photo stays on screen under a calm shimmer, with one line
/// of caption. While the app waits to retry, the caption says why and when.
struct ResultLoadingPanel: View {
    let photoPath: String
    let geometryProgress: ScanGeometryProgress?
    let isWaitingRetry: Bool
    let isRoiRequest: Bool
    let retryReason: RetryReason
    let secondsLeft: Int32
    let attempt: Int32

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShimmering = false

    var body: some View {
        VStack(spacing: 20) {
            if let progress = geometryProgress, !progress.regions.isEmpty, !isWaitingRetry {
                ScanGeometryPreview(photoPath: photoPath, progress: progress)
            } else {
                photo
            }
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                if isWaitingRetry {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var photo: some View {
        LocalPhotoView(path: photoPath, maxPixel: 1400) {
            Rectangle().fill(AppTheme.paper2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(AppTheme.paper2)
        .overlay { shimmer }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                isShimmering = true
            }
        }
    }

    /// A soft light that breathes over the photo; static for Reduce Motion.
    private var shimmer: some View {
        LinearGradient(
            colors: [AppTheme.onPhoto.opacity(0), AppTheme.onPhoto.opacity(0.35), AppTheme.onPhoto.opacity(0)],
            startPoint: isShimmering ? .topLeading : .bottomTrailing,
            endPoint: isShimmering ? .bottomTrailing : .topLeading
        )
        .opacity(reduceMotion ? 0.15 : (isShimmering ? 0.9 : 0.3))
        .blendMode(.plusLighter)
    }

    private var title: String {
        if isWaitingRetry {
            return retryReason == RetryReason.busy
                ? String(localized: "loading_busy")
                : String(localized: "loading_too_many")
        }
        if let progress = geometryProgress {
            switch progress.stage {
            case "bottles": return String(localized: "scan_preview_finding_label")
            case "labels": return String(localized: "scan_preview_checking")
            case "recognition": return String(localized: "scan_preview_recognizing")
            default: break
            }
        }
        return isRoiRequest ? String(localized: "loading_roi") : String(localized: "loading_recognizing")
    }

    private var note: String {
        L10n.format("loading_retry_in", secondsLeft, attempt, ApiConstants.shared.MAX_AUTO_RETRIES)
    }
}
