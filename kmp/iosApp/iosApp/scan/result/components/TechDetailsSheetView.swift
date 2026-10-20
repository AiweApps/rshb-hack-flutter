import SwiftUI
import SharedLogic

/// The raw facts behind an answer, one labelled value per row.
struct TechDetailsSheetView: View {
    private let component: TechDetailsComponent

    init(component: TechDetailsComponent) {
        self.component = component
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(String(localized: "result_tech_details"))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    CloseButton(action: component.onCloseClicked)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 12)
            ScrollView {
                GroupedSection(rowBackground: AppTheme.groupedRow) {
                    ForEach(Array(component.rows.enumerated()), id: \.offset) { _, row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(TechText.label(for: row.key))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(TechText.value(for: row.value))
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .fittedSheet(fullHeightBackground: AppTheme.groupedBackground)
        .presentationDragIndicator(.visible)
    }
}

/// Labels and formatted values for technical rows.
enum TechText {
    static func label(for key: TechKey) -> String {
        L10n.string(labelKey(key))
    }

    static func value(for value: TechValue) -> String {
        if let text = value as? TechValue.Text { return text.text }
        if value is TechValue.None { return String(localized: "tech_none") }
        if value is TechValue.SnapshotYes { return String(localized: "tech_snapshot_yes") }
        if value is TechValue.SnapshotNo { return String(localized: "tech_snapshot_no") }
        if value is TechValue.ProbabilityNotCalculated { return String(localized: "tech_probability_value") }
        if let file = value as? TechValue.File {
            return L10n.format("tech_file_value", file.format, file.bytes)
        }
        if let millis = value as? TechValue.Milliseconds {
            let seconds = (millis.millis / 1000).formatted(.number.precision(.fractionLength(1)))
            return L10n.format("tech_seconds", seconds)
        }
        return String(localized: "tech_none")
    }

    private static func labelKey(_ key: TechKey) -> String {
        if key == TechKey.decision { return "tech_decision" }
        if key == TechKey.primaryBasis { return "tech_primary_basis" }
        if key == TechKey.mode { return "tech_mode" }
        if key == TechKey.rawSlug { return "tech_raw_slug" }
        if key == TechKey.bestCandidate { return "tech_best_candidate" }
        if key == TechKey.cardSlug { return "tech_card_slug" }
        if key == TechKey.pageUrl { return "tech_page_url" }
        if key == TechKey.pageSource { return "tech_page_source" }
        if key == TechKey.snapshot { return "tech_snapshot" }
        if key == TechKey.roi { return "tech_roi" }
        if key == TechKey.bottles { return "tech_bottles" }
        if key == TechKey.frame { return "tech_frame" }
        if key == TechKey.file { return "tech_file" }
        if key == TechKey.probability { return "tech_probability" }
        if key == TechKey.backendTime { return "tech_backend_time" }
        if key == TechKey.profile { return "tech_profile" }
        return "tech_reasons"
    }
}
