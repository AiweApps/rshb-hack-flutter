import SwiftUI
import SharedLogic

/// The stored scans that have a match, to pick a wine for the comparison from. The sheet is as
/// tall as its rows (a few scans leave no empty space) and scrolls once they outgrow it.
struct HistoryPickerSheetView: View {
    @ObservedObject private var observableState: ObservableValue<HistoryPickerState>
    private let component: HistoryPickerComponent
    @State private var pickCount = 0

    private static let rowCorner: CGFloat = 26
    private static let thumbSize: CGFloat = 56
    private static let placeholderHeight: CGFloat = 220

    init(component: HistoryPickerComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .fittedSheet()
        .presentationBackground(AppTheme.paper)
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.selection, trigger: pickCount)
    }

    private var header: some View {
        ZStack {
            Text(String(localized: "picker_title"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            HStack {
                CloseButton(action: component.onCloseClicked)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        let state = observableState.value
        let screenState = state.screenState

        if screenState is ScreenState.Loading {
            LoadingStateView()
                .frame(height: Self.placeholderHeight)
        } else if let error = screenState as? ScreenState.Error {
            ErrorStateView(error: error.error, onRetry: nil)
                .frame(minHeight: Self.placeholderHeight)
        } else if screenState is ScreenState.Content {
            if state.items.isEmpty {
                EmptyStateView(
                    systemImage: "clock.arrow.circlepath",
                    message: String(localized: "picker_empty")
                )
                .frame(height: Self.placeholderHeight)
            } else {
                ScrollView {
                    rows(state)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private func rows(_ state: HistoryPickerState) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(state.items.enumerated()), id: \.element.id) { index, item in
                Button {
                    pickCount += 1
                    component.onScanClicked(scanId: item.id)
                } label: {
                    row(item, isInCompare: state.isInCompare(item: item))
                }
                .buttonStyle(.plain)
                if index < state.items.count - 1 {
                    Divider()
                        .padding(.leading, 16 + Self.thumbSize + 14)
                }
            }
        }
        .background(AppTheme.paper2, in: RoundedRectangle(cornerRadius: Self.rowCorner, style: .continuous))
    }

    private func row(_ item: ScanHistoryItem, isInCompare: Bool) -> some View {
        HStack(spacing: 14) {
            LocalPhotoView(path: item.photoPath, maxPixel: 200) {
                Rectangle().fill(AppTheme.paper2)
            }
            .frame(width: Self.thumbSize, height: Self.thumbSize)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.presentationTitle ?? String(localized: "history_no_match"))
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                if let producer = item.bestProducer, !producer.isEmpty,
                   producer.caseInsensitiveCompare(item.presentationTitle ?? "") != .orderedSame {
                    Text(producer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if isInCompare {
                AppIcon(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.wine)
                    .accessibilityLabel(String(localized: "history_in_compare"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
