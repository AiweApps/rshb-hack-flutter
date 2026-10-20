import SwiftUI
import SharedLogic

/// Every wine stays accounted for: listed pairing, missing category, or no source data.
struct PairingResultsView: View {
    let state: DishPairingState
    let dish: DishLabel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if state.hasNoMatches {
                Text(String(localized: "pairing_no_matches_body"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink2)
            }
            if !state.matched.isEmpty {
                section(
                    String(localized: "pairing_listed_header"),
                    trailing: L10n.format("pairing_count_of", Int32(state.matched.count), state.wineCount),
                    matches: state.matched,
                    kind: .matched
                )
            }
            if !state.unmatched.isEmpty {
                section(
                    String(localized: "pairing_not_listed"),
                    trailing: "\(state.unmatched.count)",
                    matches: state.unmatched,
                    kind: .notListed
                )
            }
            if !state.withoutData.isEmpty {
                section(
                    String(localized: "pairing_no_data_header"),
                    trailing: "\(state.withoutData.count)",
                    matches: state.withoutData,
                    kind: .noData
                )
            }
        }
    }

    private func section(
        _ title: String,
        trailing: String,
        matches: [PairingMatch],
        kind: PairingMatchRow.Kind
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                Spacer(minLength: 8)
                Text(trailing)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.ink2)
            .accessibilityAddTraits(.isHeader)
            ForEach(matches, id: \.card.slug) { match in
                PairingMatchRow(match: match, dish: dish, kind: kind, referenceAccess: state.referenceAccess)
                if match.card.slug != matches.last?.card.slug {
                    Divider().overlay(AppTheme.rule)
                }
            }
        }
    }
}
