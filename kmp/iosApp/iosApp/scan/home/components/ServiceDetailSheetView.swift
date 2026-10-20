import SwiftUI
import SharedLogic

/// The explanation behind a status pill: what the state means and that it refreshes itself.
/// Shared by the scan tab and the settings screen.
struct ServiceDetailSheetView: View {
    private let component: ServiceDetailComponent

    init(component: ServiceDetailComponent) {
        self.component = component
    }

    var body: some View {
        let availability = component.availability

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ServiceStatusDot(availability: availability)
                Text(ServiceStateText.label(for: availability))
                    .font(.title3.weight(.semibold))
            }
            Text(ServiceStateText.detail(for: availability))
                .font(.body)
            Text(String(localized: "status_auto_refresh"))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                component.onCloseClicked()
            } label: {
                Text(String(localized: "common_got_it"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .appPrimaryButtonStyle()
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fittedSheet()
        .presentationDragIndicator(.visible)
    }
}
