import SwiftUI
import SharedLogic

/// One wine of the set as a compact row: its photo with the ordinal the table columns
/// repeat, name, producer and the remove button. A tap on the row unfolds the description
/// and the catalogue link.
struct CompareEntryHeader: View {
    @State private var isExpanded = false
    let entry: CompareEntry
    let ordinal: Int
    let referenceAccess: ReferenceAccess?
    let onRemove: () -> Void
    let onLink: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 4) {
                if hasDetails {
                    Button {
                        withAnimation(.snappy) { isExpanded.toggle() }
                    } label: {
                        summary
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(String(localized: isExpanded ? "compare_hide_description" : "compare_description"))
                } else {
                    summary
                        .accessibilityElement(children: .combine)
                }

                Button(action: onRemove) {
                    AppIcon(systemName: "xmark")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "compare_remove"))
            }

            if isExpanded {
                details
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: 10) {
            CompareWineOrdinal(ordinal: ordinal)

            WinePhotoView(
                card: entry.card,
                photoPath: entry.photoPath,
                crop: entry.crop,
                frame: entry.frame,
                referenceAccess: referenceAccess
            )
            .frame(width: 36, height: 48)
            .background(AppTheme.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.card.presentationTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                if let producer = entry.card.producer, !producer.isEmpty,
                   producer.caseInsensitiveCompare(entry.card.presentationTitle) != .orderedSame {
                    Text(producer)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.ink2)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if hasDetails {
                AppIcon(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }

    private var hasDetails: Bool {
        entry.card.description_?.isEmpty == false || entry.card.catalogueUrl != nil
    }

    @ViewBuilder
    private var details: some View {
        if let description = entry.card.description_, !description.isEmpty {
            Text(description)
                .font(.footnote)
                .foregroundStyle(AppTheme.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 12)
        }
        if let url = entry.card.catalogueUrl {
            Button {
                onLink(url)
            } label: {
                CatalogueLinkLabel(title: String(localized: "common_open_catalogue"))
                    .font(.footnote.weight(.medium))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(AppTheme.wine)
        }
    }
}

/// The wine's number, shared by its row and its table column.
struct CompareWineOrdinal: View {
    let ordinal: Int

    var body: some View {
        Text(ordinal.formatted())
            .font(.caption2.weight(.medium))
            .foregroundStyle(AppTheme.ink2)
            .frame(width: 20, height: 20)
            .background(AppTheme.paper2, in: Circle())
    }
}

/// A table column's heading: the wine's number and name.
struct CompareColumnTitle: View {
    let ordinal: Int
    let title: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            CompareWineOrdinal(ordinal: ordinal)
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
