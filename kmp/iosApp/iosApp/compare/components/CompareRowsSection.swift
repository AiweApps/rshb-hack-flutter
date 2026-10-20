import SwiftUI
import SharedLogic

extension WineCompareState {

    /// The rows the switch asks for: every row in table order, or only the disagreements.
    var visibleRows: [CompareRow] {
        showAll ? allRows : differentRows
    }
}

/// The rows in the stacked layout as one grouped block: the attribute name, then one cell
/// per wine in equal columns. A row where the wines agree is drawn quieter.
///
/// With `stacksLongRows`, prose rows (grapes, region, pairings) list the wines one under
/// another by number instead, so three columns never squeeze long text.
struct CompareRowsSection: View {
    let rows: [CompareRow]
    var stacksLongRows = false

    var body: some View {
        GroupedSection {
            ForEach(rows, id: \.attribute) { row in
                VStack(alignment: .leading, spacing: 6) {
                    Text(CompareAttributeLabel.text(for: row.attribute))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                    if stacksLongRows && Self.isLong(row.attribute) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(row.values.enumerated()), id: \.offset) { index, value in
                                HStack(alignment: .top, spacing: 8) {
                                    CompareWineOrdinal(ordinal: index + 1)
                                    CompareCell(value: value, isQuiet: !row.isDifferent)
                                }
                            }
                        }
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(row.values.enumerated()), id: \.offset) { _, value in
                                CompareCell(value: value, isQuiet: !row.isDifferent)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private static func isLong(_ attribute: CompareAttribute) -> Bool {
        attribute == CompareAttribute.grapes || attribute == CompareAttribute.region ||
            attribute == CompareAttribute.pairings
    }
}

/// «Everything matches», for the differences view of wines that do not differ.
struct CompareNoDifferencesText: View {
    var body: some View {
        Text(String(localized: "compare_no_differences"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}
