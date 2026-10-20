import SwiftUI
import SharedLogic

/// Three wines at accessibility text sizes do not fit side by side: column titles and rows
/// share one horizontal scroll, and the attribute column stays put while the wines slide under it.
struct CompareSidewaysTable: View {
    let state: WineCompareState

    @State private var pinnedOffset: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 16) {
                headers
                if state.visibleRows.isEmpty {
                    CompareNoDifferencesText()
                        .offset(x: pinnedOffset)
                } else {
                    section(rows: state.visibleRows)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.visible)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            let maxOffset = max(geometry.contentSize.width - geometry.containerSize.width, 0)
            return min(max(geometry.contentOffset.x, 0), maxOffset)
        } action: { _, offset in
            pinnedOffset = offset
        }
    }

    private var totalWidth: CGFloat {
        Metrics.labelWidth + CGFloat(state.entries.count) * (Metrics.columnWidth + Metrics.gap)
    }

    private var headers: some View {
        HStack(alignment: .top, spacing: Metrics.gap) {
            Color.clear.frame(width: Metrics.labelWidth, height: 1)
            ForEach(Array(state.entries.enumerated()), id: \.element.slug) { index, entry in
                CompareColumnTitle(ordinal: index + 1, title: entry.card.presentationTitle)
                    .padding(.horizontal, 8)
                    .frame(width: Metrics.columnWidth)
            }
        }
        .frame(width: totalWidth, alignment: .leading)
    }

    private func section(rows: [CompareRow]) -> some View {
        GroupedSection {
            ForEach(rows, id: \.attribute) { row in
                HStack(alignment: .top, spacing: Metrics.gap) {
                    Text(CompareAttributeLabel.text(for: row.attribute))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .padding(.leading, 16)
                        .padding(.vertical, 12)
                        .frame(width: Metrics.labelWidth, alignment: .leading)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                        .background(AppTheme.card)
                        .offset(x: pinnedOffset)
                        .zIndex(1)
                    ForEach(Array(row.values.enumerated()), id: \.offset) { _, value in
                        CompareCell(value: value, isQuiet: !row.isDifferent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .frame(width: Metrics.columnWidth, alignment: .leading)
                    }
                }
                .frame(width: totalWidth, alignment: .leading)
            }
        }
        .frame(width: totalWidth)
    }
}

/// Column sizes of the sideways table.
private enum Metrics {
    static let labelWidth: CGFloat = 96
    static let columnWidth: CGFloat = 156
    static let gap: CGFloat = 8
}
