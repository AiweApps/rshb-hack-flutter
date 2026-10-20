import SwiftUI
import SharedLogic

/// The recent scans as a panel docked to the bottom of the tab: a title row with «All» and
/// one horizontal row of cards. Looks like a sheet on a matte surface but is fixed, and not a `.sheet` (a modal one
/// would cover the tab bar); the full list is the History tab, which «All» opens.
///
/// The content stays above the bottom safe area (the floating tab bar on iOS 26), so the cards
/// are never hidden by the bar; only the panel's surface continues underneath it.
struct RecentScansPanel: View {
    let items: [ScanHistoryItem]
    /// Reports the panel's height, so the caller can leave that much room under whatever sits
    /// above the panel.
    @Binding var contentHeight: CGFloat
    let onItemTap: (Int64) -> Void
    let onAllTap: () -> Void

    @State private var stripHeight: CGFloat = Metrics.stripGuess

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: Metrics.corner,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: Metrics.corner,
            style: .continuous
        )

        VStack(spacing: 0) {
            header
            strip
                .padding(.bottom, Metrics.stripBottomGap)
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        // The surface carries on under the tab bar; the content above does not.
        .background {
            background(shape: shape)
                .shadow(color: AppTheme.ink.opacity(0.14), radius: 14, y: -5)
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    // MARK: Parts

    private var header: some View {
        HStack {
            Text(String(localized: "scan_recent_title"))
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(String(localized: "scan_recent_all"), action: onAllTap)
                .font(.body.weight(.medium))
                .tint(AppTheme.wine)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items, id: \.id) { item in
                    RecentScanCard(item: item) { onItemTap(item.id) }
                }
            }
            .padding(.horizontal, 20)
            // Room for the card shadows, which the scroll view would otherwise clip.
            .padding(.vertical, 4)
            // Measured on the content: a horizontal scroll view takes whatever height it is
            // offered, so measuring it would feed the panel's own height back into itself.
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { stripHeight = $0 }
        }
        .frame(height: stripHeight)
    }

    /// A quiet solid surface, as the cards: content is not glass. It carries on under the tab bar.
    private func background<S: InsettableShape>(shape: S) -> some View {
        shape.fill(AppTheme.card)
            .overlay { shape.strokeBorder(AppTheme.rule, lineWidth: 0.5) }
    }

    private enum Metrics {
        static let corner: CGFloat = 34
        static let stripGuess: CGFloat = 130
        static let stripBottomGap: CGFloat = 12
    }
}
