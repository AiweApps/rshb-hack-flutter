import SwiftUI
import SharedLogic

/// The compact «Add to / Remove from comparison» action a card in a list can carry.
struct WineCardCompare {
    let isInCompare: Bool
    let onAdd: () -> Void
    let onRemove: () -> Void
}

/// A wine from the catalogue. The best match carries the photo comparison as a `header`;
/// other cards show the reference as a thumbnail. Tapping the body is `onTap`; the link row
/// is its own button.
struct WineCardView<Header: View>: View {
    let card: WineCard
    let tag: String?
    let isBest: Bool
    let referenceUrl: String?
    let referenceAccess: ReferenceAccess?
    let onTap: (() -> Void)?
    let onLinkTap: (String) -> Void
    var compare: WineCardCompare?
    @ViewBuilder let header: () -> Header

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header()
            content(tappable: onTap != nil)
            compareRow
            linkRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appMatteCard()
    }

    private func content(tappable: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            if Header.self == EmptyView.self {
                AuthorizedAsyncImage(url: referenceUrl, access: referenceAccess) {
                    ProgressView()
                } failure: {
                    AppIcon(systemName: "wineglass")
                        .font(.title2)
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(6)
                .frame(width: 74, height: 108)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.rule.opacity(0.45)))
            }
            VStack(alignment: .leading, spacing: 5) {
                if let tag {
                    Text(tag)
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.7)
                        .foregroundStyle(isBest ? AppTheme.wine : AppTheme.muted)
                }
                Text(card.presentationTitle)
                    .font(AppTheme.wineTitle)
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let producer = card.producer, !producer.isEmpty,
                   producer.caseInsensitiveCompare(card.presentationTitle) != .orderedSame {
                    Text(producer)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.ink2)
                }
                if !card.metaLine.isEmpty {
                    Text(card.metaLine)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
            if tappable {
                AppIcon(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(tappable ? .isButton : [])
    }

    @ViewBuilder
    private var compareRow: some View {
        if let compare {
            Divider().overlay(AppTheme.rule.opacity(0.7))
            AddToCompareButton(
                isInCompare: compare.isInCompare,
                style: .compact,
                onAdd: compare.onAdd,
                onRemove: compare.onRemove
            )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var linkRow: some View {
        Divider().overlay(AppTheme.rule.opacity(0.7))
        if let url = card.catalogueUrl {
            Button {
                onLinkTap(url)
            } label: {
                CatalogueLinkLabel(title: String(localized: "result_open_on_site"))
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .foregroundStyle(AppTheme.wine)
        } else {
            Text(String(localized: "result_no_site_url"))
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
    }
}

extension WineCardView where Header == EmptyView {
    init(
        card: WineCard,
        tag: String?,
        isBest: Bool,
        referenceUrl: String?,
        referenceAccess: ReferenceAccess?,
        onTap: (() -> Void)?,
        onLinkTap: @escaping (String) -> Void,
        compare: WineCardCompare? = nil
    ) {
        self.init(
            card: card,
            tag: tag,
            isBest: isBest,
            referenceUrl: referenceUrl,
            referenceAccess: referenceAccess,
            onTap: onTap,
            onLinkTap: onLinkTap,
            compare: compare,
            header: { EmptyView() }
        )
    }
}
