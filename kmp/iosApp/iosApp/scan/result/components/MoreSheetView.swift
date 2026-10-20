import SwiftUI
import SharedLogic

/// «More»: recognise only the selected bottle, choose a frame, share the answer as JSON, technical details.
struct MoreSheetView: View {
    private let component: MoreComponent
    private let onRemoveFromCompare: (() -> Void)?

    init(component: MoreComponent, onRemoveFromCompare: (() -> Void)? = nil) {
        self.component = component
        self.onRemoveFromCompare = onRemoveFromCompare
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "result_more"))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            GroupedSection(rowBackground: AppTheme.groupedRow) {
                if let onRemoveFromCompare {
                    row(title: String(localized: "result_remove_from_compare"),
                        systemImage: "minus.circle", action: onRemoveFromCompare)
                }
                if component.canRescanBottle, let number = component.bottleNumber_ {
                    row(
                        title: L10n.format("result_rescan_bottle", number.int32Value),
                        systemImage: "viewfinder",
                        action: component.onRescanBottleClicked
                    )
                }
                if component.canDrawFrame {
                    row(
                        title: String(localized: "result_choose_frame"),
                        systemImage: "crop",
                        action: component.onDrawFrameClicked
                    )
                }
                row(
                    title: String(localized: "result_share_json"),
                    systemImage: "square.and.arrow.up",
                    action: component.onShareFullClicked
                )
                if let number = component.bottleNumber_ {
                    row(
                        title: component.isRoi
                            ? String(localized: "result_share_frame_json")
                            : L10n.format("result_share_bottle_json", number.int32Value),
                        systemImage: "square.and.arrow.up",
                        action: component.onShareBottleClicked
                    )
                }
                row(
                    title: String(localized: "result_tech_details"),
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    action: component.onTechDetailsClicked
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .fittedSheet(fullHeightBackground: AppTheme.groupedBackground)
        .presentationDragIndicator(.visible)
    }

    private func row(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, appSymbol: systemImage)
                    .foregroundStyle(AppTheme.wine)
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
