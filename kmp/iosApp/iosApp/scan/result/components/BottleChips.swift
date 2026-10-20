import SwiftUI
import SharedLogic

/// The bottle switcher: «All» and one chip per bottle (the one near the centre is marked,
/// the winner of an automatic answer wears a crown).
struct BottleChips: View {
    let view: RecognitionView
    let selectedInstanceId: String?
    let winnerInstanceId: String?
    let onSelect: (String?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: String(localized: "result_tab_all"), isSelected: selectedInstanceId == nil, isWinner: false) {
                    onSelect(nil)
                }
                ForEach(view.bottles, id: \.instanceId) { bottle in
                    chip(
                        title: title(for: bottle),
                        isSelected: bottle.instanceId == selectedInstanceId,
                        isWinner: bottle.instanceId == winnerInstanceId
                    ) {
                        onSelect(bottle.instanceId)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .sensoryFeedback(.selection, trigger: selectedInstanceId)
    }

    private func title(for bottle: RecognizedBottle) -> String {
        view.isNearCenter(bottle: bottle)
            ? L10n.format("result_bottle_near_center_tag", bottle.number)
            : L10n.format("result_bottle_n", bottle.number)
    }

    private func chip(title: String, isSelected: Bool, isWinner: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isWinner {
                    CrownMark()
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? AppTheme.onWine : AppTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(isSelected ? AppTheme.wine : AppTheme.paper2, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : AppTheme.rule))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isWinner ? "\(title), \(String(localized: "result_best_match"))" : title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The winner's crown; it bounces once when it first shows.
private struct CrownMark: View {
    @State private var didAppear = false

    var body: some View {
        AppIcon(systemName: "crown.fill")
            .font(.footnote)
            .foregroundStyle(AppTheme.gold)
            .symbolEffect(.bounce, options: .nonRepeating, value: didAppear)
            .accessibilityHidden(true)
            .onAppear { didAppear = true }
    }
}
