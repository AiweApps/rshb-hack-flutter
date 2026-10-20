import SwiftUI
import SharedLogic

/// The catalogue photo of the wine, large, aspect-fit on a paper plate.
struct WineReferencePhotoView: View {
    let url: String?
    let access: ReferenceAccess?

    var height: CGFloat = 300

    var body: some View {
        AuthorizedAsyncImage(url: url, access: access) {
            ProgressView()
        } failure: {
            Text(String(localized: "result_reference_missing"))
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(8)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(AppTheme.paper2, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityLabel(String(localized: "result_reference"))
    }
}
