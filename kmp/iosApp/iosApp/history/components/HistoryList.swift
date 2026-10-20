import SwiftUI
import SharedLogic

/// Saved dish choices on top, then the scans by day. Swipe left deletes.
struct HistoryList: View {
    let state: HistoryState
    let component: HistoryComponent

    var body: some View {
        List {
            if !state.savedPairings.isEmpty {
                Section {
                    ForEach(state.savedPairings, id: \.id) { pairing in
                        SavedPairingRowView(pairing: pairing, dishLabel: state.dishLabelOf(pairing: pairing)) {
                            component.onSavedPairingClicked(pairingId: pairing.id)
                        }
                        .listRowBackground(AppTheme.paper2)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                component.onSavedPairingDismissed(pairingId: pairing.id)
                            } label: {
                                Label(String(localized: "history_delete"), appSymbol: "trash")
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "history_saved_pairings"))
                }
            }
            ForEach(state.sections, id: \.day) { section in
                Section {
                    ForEach(section.items, id: \.id) { item in
                        row(item)
                    }
                } header: {
                    HistoryDayHeader(day: section.day)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func row(_ item: ScanHistoryItem) -> some View {
        HistoryRowView(
            item: item,
            isPendingDelete: state.pendingDeleteIds.contains(KotlinLong(value: item.id)),
            isFavorite: state.isFavorite(item: item),
            isInCompare: state.isInCompare(item: item),
            onTap: { component.onScanClicked(scanId: item.id) },
            onFavorite: { component.onFavoriteClicked(scanId: item.id) },
            onCompare: { component.onCompareClicked(scanId: item.id) }
        )
        .listRowBackground(AppTheme.paper)
        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 12))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                component.onScanDismissed(scanId: item.id)
            } label: {
                Label(String(localized: "history_delete"), appSymbol: "trash")
            }
        }
    }
}
