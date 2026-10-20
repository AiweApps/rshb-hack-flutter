import SwiftUI
import SharedLogic

struct OnboardingView: View {
    @ObservedObject private var observableState: ObservableValue<OnboardingState>
    private let component: OnboardingComponent

    init(component: OnboardingComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
    }

    var body: some View {
        let state = observableState.value
        if state.screenState is ScreenState.Loading {
            LoadingStateView()
        } else if let error = state.screenState as? ScreenState.Error {
            ErrorStateView(error: error.error, onRetry: nil)
        } else if state.screenState is ScreenState.Content {
            VStack(spacing: 0) {
                header(state)
                OnboardingMotionStoryView(
                    page: Int(state.pageIndex),
                    onPageChanged: { component.onPageChanged(pageIndex: Int32($0)) }
                )
                footer(state)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.paper.ignoresSafeArea())
            .sensoryFeedback(.selection, trigger: state.pageIndex)
        }
    }

    private func header(_ state: OnboardingState) -> some View {
        HStack {
            Button { component.onPageChanged(pageIndex: state.pageIndex - 1) } label: {
                AppIcon(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 30, height: 30)
            }
            .appSecondaryButtonStyle()
            .buttonBorderShape(.circle)
            .accessibilityLabel(String(localized: "common_back"))
            .opacity(state.pageIndex > 0 ? 1 : 0)
            .disabled(state.pageIndex == 0)
            .accessibilityHidden(state.pageIndex == 0)
            Spacer()
            Text(String(format: String(localized: "onboarding_progress"), Int(state.pageIndex) + 1, Int(state.pageCount)))
                .font(.footnote).foregroundStyle(AppTheme.muted)
                .accessibilityAddTraits(.updatesFrequently)
            Spacer()
            Button(String(localized: "onboarding_skip"), action: component.onSkipClicked)
                .font(.subheadline).foregroundStyle(AppTheme.ink2)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func footer(_ state: OnboardingState) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                OnboardingPageDots(count: Int(state.pageCount), index: Int(state.pageIndex))
                Spacer(minLength: 0)
                Button(action: component.onNextClicked) {
                    HStack(spacing: 8) {
                        Text(String(localized: state.isLastPage ? "onboarding_open_assistant" : "onboarding_next"))
                        AppIcon(systemName: "arrow.right").font(.subheadline.weight(.semibold))
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.onWine)
                    // Regular control size plus this inset keeps the capsule near 44–48 pt.
                    .padding(.horizontal, state.isLastPage ? 12 : 6)
                    .padding(.vertical, 5)
                }
                .appPrimaryButtonStyle()
                .controlSize(.regular)
                .animation(.smooth(duration: 0.3), value: state.isLastPage)
            }
            Text(String(localized: "disclaimer"))
                .font(.caption2).foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: 520)
    }
}
