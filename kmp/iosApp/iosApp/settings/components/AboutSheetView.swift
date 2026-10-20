import SwiftUI
import SharedLogic

struct AboutSheetView: View {
    private let component: AboutComponent

    init(component: AboutComponent) {
        self.component = component
    }

    var body: some View {
        VStack(spacing: 16) {
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
            Text(String(localized: "app_name"))
                .font(.title2.bold())
            ScrollView {
                Text(String(localized: "settings_about_body"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .scrollBounceBehavior(.basedOnSize)
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
        .fittedSheet()
        .presentationDragIndicator(.visible)
    }
}
