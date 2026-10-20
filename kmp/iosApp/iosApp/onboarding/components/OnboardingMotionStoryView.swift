import SwiftUI

/// One catalogue bottle persists across the three pages and moves between them.
/// The shared component owns the page; only the illustration phases live here.
struct OnboardingMotionStoryView: View {
    let page: Int
    let onPageChanged: (Int) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scanDone = false
    @State private var sweepDone = false
    @State private var dinnerStep = 0

    private var titleKey: String { ["intro_scan_title", "intro_compare_title", "intro_dinner_title"][page] }
    private var bodyKey: String { ["intro_scan_body", "intro_compare_body", "intro_dinner_body"][page] }
    private var accessibilityKey: String { ["intro_access_scan", "intro_access_compare", "intro_access_dinner"][page] }

    private var bottleMotion: Animation? { reduceMotion ? nil : .smooth(duration: 0.7) }
    private var sceneTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .opacity.animation(.easeOut(duration: 0.3).delay(0.22)),
            removal: .opacity.animation(.easeIn(duration: 0.14))
        )
    }

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(String(localized: "intro_demo"))
                            .font(.caption.weight(.medium)).foregroundStyle(AppTheme.muted)
                        stage
                            .frame(height: page == 2
                                ? max(460, min(480, viewport.size.height - 170))
                                : min(430, max(340, viewport.size.height - 215)))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(L10n.string(accessibilityKey))
                        ZStack(alignment: .topLeading) {
                            copy.id(page).transition(sceneTransition)
                        }
                        .animation(.easeOut(duration: 0.3), value: page)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .id("intro-top")
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity, minHeight: viewport.size.height, alignment: .top)
                }
                .onChange(of: page) { _, _ in reader.scrollTo("intro-top", anchor: .top) }
            }
            .simultaneousGesture(DragGesture(minimumDistance: 35).onEnded { value in
                guard abs(value.translation.width) > 75,
                      abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                onPageChanged(min(2, max(0, page + (value.translation.width < 0 ? 1 : -1))))
            })
        }
        // A new page or Reduce Motion change cancels the running phase before it can update.
        .task(id: "\(page)-\(reduceMotion)") { await runPhases() }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string(titleKey))
                .font(.system(.title, design: .serif).weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Text(L10n.string(bodyKey))
                .font(.subheadline).foregroundStyle(AppTheme.ink2)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stage: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let bottle = bottleFrame(in: size)
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    scene(size: size, bottle: bottle).id(page).transition(sceneTransition)
                }
                .animation(.easeOut(duration: 0.3), value: page)
                Image("intro_sauvignon").resizable().scaledToFit()
                    .frame(width: bottle.width, height: bottle.height)
                    .shadow(color: AppTheme.scrim.opacity(page == 2 ? 0 : 0.12), radius: 14, y: 10)
                    .position(x: bottle.midX, y: bottle.midY)
                    .animation(bottleMotion, value: page)
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func scene(size: CGSize, bottle: CGRect) -> some View {
        switch page {
        case 0:
            OnboardingScanScene(
                size: size, bottle: bottle, scanDone: scanDone, sweepDone: sweepDone, reduceMotion: reduceMotion
            )
        case 1:
            OnboardingCompareScene(bottleTop: bottle.minY, bottleHeight: bottle.height)
        default:
            OnboardingDinnerScene(step: dinnerStep, bottleSlot: CGSize(width: bottle.maxX, height: bottle.height))
        }
    }

    private func bottleFrame(in size: CGSize) -> CGRect {
        switch page {
        case 0:
            let height = size.height * 0.8
            let width = height * Self.bottleAspect
            let midX = scanDone ? width / 2 + 18 : size.width / 2
            return CGRect(x: midX - width / 2, y: size.height * 0.44 - height / 2, width: width, height: height)
        case 1:
            let height = size.height * 0.5
            let width = height * Self.bottleAspect
            return CGRect(x: size.width * 0.25 - width / 2, y: 4, width: width, height: height)
        default:
            let height: CGFloat = 50
            return CGRect(x: 4, y: 0, width: height * Self.bottleAspect, height: height)
        }
    }

    private func runPhases() async {
        if page != 0 { scanDone = true }
        if page != 2, dinnerStep > 0 { dinnerStep = Self.dinnerSteps }
        if reduceMotion {
            scanDone = true
            dinnerStep = Self.dinnerSteps
            return
        }
        if page == 0, !scanDone {
            withAnimation(.easeInOut(duration: 1.0)) { sweepDone = true }
            guard await pause(milliseconds: 1150) else { return }
            withAnimation(.smooth(duration: 0.7)) { scanDone = true }
        }
        if page == 2 {
            while dinnerStep < Self.dinnerSteps {
                guard await pause(milliseconds: dinnerStep == 0 ? 550 : 600) else { return }
                withAnimation(.smooth(duration: 0.35)) { dinnerStep += 1 }
            }
        }
    }

    private func pause(milliseconds: Int) async -> Bool {
        do {
            try await Task.sleep(for: .milliseconds(milliseconds))
            return true
        } catch {
            return false
        }
    }

    private static let bottleAspect: CGFloat = 231 / 900
    private static let dinnerSteps = OnboardingDinnerScene.lastStep
}
