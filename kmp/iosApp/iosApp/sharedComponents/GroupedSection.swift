import SwiftUI

/// An inset-grouped block outside a `List`: a small header (with an optional trailing note),
/// rounded rows with hairlines between them, and an optional footer. Used where the content
/// around the rows (chips, photos, a wide table) rules a `List` out.
struct GroupedSection<Content: View>: View {
    var title: String?
    var trailing: String?
    var footer: String?
    /// Colour of the rows. A sheet on the system's glass passes `AppTheme.groupedRow` and sets
    /// the matching grouped background itself, as a `List` there would.
    var rowBackground: Color = AppTheme.card
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                HStack {
                    Text(title)
                    Spacer(minLength: 8)
                    if let trailing {
                        Text(trailing)
                    }
                }
                .font(.footnote)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                Group(subviews: content()) { subviews in
                    ForEach(subviews.indices, id: \.self) { index in
                        subviews[index]
                        if index < subviews.count - 1 {
                            Divider().overlay(AppTheme.rule).padding(.leading, 16)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 16)
            }
        }
    }
}
