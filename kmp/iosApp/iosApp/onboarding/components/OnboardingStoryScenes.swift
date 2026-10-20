import SwiftUI

/// Page 1: the label is framed once, then the bottle steps aside for its catalogue card.
struct OnboardingScanScene: View {
    let size: CGSize
    let bottle: CGRect
    let scanDone: Bool
    let sweepDone: Bool
    let reduceMotion: Bool

    var body: some View {
        let frame = bottle.insetBy(dx: -24, dy: -12)
        ZStack(alignment: .topLeading) {
            if scanDone {
                card
                    .frame(width: size.width - bottle.maxX - 20, alignment: .leading)
                    .position(x: (bottle.maxX + 20 + size.width) / 2, y: bottle.midY)
                    .transition(reduceMotion ? AnyTransition.identity : .asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 16))
                            .animation(.smooth(duration: 0.45).delay(0.2)),
                        removal: .opacity
                    ))
            } else {
                Group {
                    ViewfinderCorners()
                        .stroke(
                            AppTheme.wine.opacity(0.6),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                    Capsule().fill(AppTheme.wine.opacity(0.55))
                        .frame(width: frame.width - 20, height: 2)
                        .position(x: frame.midX, y: sweepDone ? frame.maxY - 12 : frame.minY + 12)
                    Label(String(localized: "intro_scanning"), appSymbol: "viewfinder")
                        .font(.caption.weight(.medium)).foregroundStyle(AppTheme.ink2)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .appGlass(in: Capsule())
                        .position(x: size.width / 2, y: size.height - 20)
                }
                .transition(.opacity.animation(.easeOut(duration: 0.2)))
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "intro_found"), appSymbol: "checkmark.circle.fill")
                .font(.caption.weight(.medium)).foregroundStyle(AppTheme.wine)
            VStack(alignment: .leading, spacing: 3) {
                Text(String(localized: "intro_sauvignon"))
                    .font(.title3.weight(.semibold)).foregroundStyle(AppTheme.ink)
                Text(String(localized: "intro_region"))
                    .font(.footnote).foregroundStyle(AppTheme.muted)
            }
            Rectangle().fill(AppTheme.rule).frame(height: 0.5)
            fact("intro_colour", "intro_white")
            fact("intro_notes", "intro_citrus")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appMatteCard(cornerRadius: 20)
        .shadow(color: AppTheme.scrim.opacity(0.06), radius: 16, y: 8)
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.string(label)).font(.caption).foregroundStyle(AppTheme.muted)
            Text(L10n.string(value)).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
        }
    }
}

/// Page 2: the same catalogue fields for both wines, the first bottle drawn by the parent.
struct OnboardingCompareScene: View {
    let bottleTop: CGFloat
    let bottleHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(maxWidth: .infinity)
                Image("intro_malbec").resizable().scaledToFit()
                    .shadow(color: AppTheme.scrim.opacity(0.12), radius: 14, y: 10)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: bottleHeight)
            .padding(.top, bottleTop)
            HStack(alignment: .top, spacing: 0) {
                wineName("intro_sauvignon")
                wineName("intro_malbec")
            }
            .padding(.top, 12)
            VStack(spacing: 0) {
                hairline
                row("intro_colour", "intro_white", "intro_red")
                hairline
                row("intro_notes", "intro_citrus", "intro_cherry")
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var hairline: some View {
        Rectangle().fill(AppTheme.rule).frame(height: 0.5)
    }

    private func wineName(_ key: String) -> some View {
        VStack(spacing: 2) {
            Text(L10n.string(key)).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink)
            Text(String(localized: "intro_region")).font(.caption2).foregroundStyle(AppTheme.muted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func row(_ label: String, _ first: String, _ second: String) -> some View {
        VStack(spacing: 4) {
            Text(L10n.string(label)).font(.caption2).foregroundStyle(AppTheme.muted)
            HStack(spacing: 0) {
                Text(L10n.string(first)).frame(maxWidth: .infinity)
                Text(L10n.string(second)).frame(maxWidth: .infinity)
            }
            .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
        }
        .padding(.vertical, 7)
    }
}

/// Page 3: an illustrative exchange that keeps the chosen wine and ends in one dish.
struct OnboardingDinnerScene: View {
    static let lastStep = 4

    let step: Int
    let bottleSlot: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Color.clear.frame(width: bottleSlot.width, height: bottleSlot.height)
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "intro_selected")).font(.caption2).foregroundStyle(AppTheme.muted)
                    Text(String(localized: "intro_sauvignon"))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink)
                    Text(String(localized: "intro_region")).font(.caption2).foregroundStyle(AppTheme.muted)
                }
            }
            Rectangle().fill(AppTheme.rule).frame(height: 0.5)
            userBubble("intro_dinner_question").revealed(step >= 1)
            Text(String(localized: "intro_dinner_time_question"))
                .font(.subheadline).foregroundStyle(AppTheme.ink)
                .revealed(step >= 2)
            userBubble("intro_dinner_time_answer").revealed(step >= 3)
            dish.revealed(step >= 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func userBubble(_ key: String) -> some View {
        HStack {
            Spacer(minLength: 48)
            Text(L10n.string(key))
                .font(.subheadline).foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(AppTheme.paper2, in: UnevenRoundedRectangle(
                    topLeadingRadius: 16, bottomLeadingRadius: 16,
                    bottomTrailingRadius: 5, topTrailingRadius: 16
                ))
        }
    }

    private var dish: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The photo takes whatever height the conversation leaves, so the card never spills out.
            Color.clear
                .frame(minHeight: 64, maxHeight: 156)
                .overlay { Image("intro_dinner").resizable().scaledToFill() }
                .clipped()
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "intro_pasta"))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink)
                    Text(String(localized: "intro_dish_meta")).font(.caption).foregroundStyle(AppTheme.muted)
                }
                Spacer(minLength: 8)
                Label(String(localized: "intro_find_ingredients"), appSymbol: "basket")
                    .font(.footnote.weight(.semibold)).foregroundStyle(AppTheme.wine)
                    .fixedSize()
            }
            .padding(12)
        }
        .appMatteCard(cornerRadius: 18)
    }
}

private struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(26, rect.width / 4, rect.height / 4)
        var path = Path()
        path.addLines([CGPoint(x: rect.minX, y: rect.minY + length), CGPoint(x: rect.minX, y: rect.minY),
                       CGPoint(x: rect.minX + length, y: rect.minY)])
        path.addLines([CGPoint(x: rect.maxX - length, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                       CGPoint(x: rect.maxX, y: rect.minY + length)])
        path.addLines([CGPoint(x: rect.maxX, y: rect.maxY - length), CGPoint(x: rect.maxX, y: rect.maxY),
                       CGPoint(x: rect.maxX - length, y: rect.maxY)])
        path.addLines([CGPoint(x: rect.minX + length, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY),
                       CGPoint(x: rect.minX, y: rect.maxY - length)])
        return path
    }
}

private extension View {
    /// Space stays reserved, so later steps never move the ones already shown.
    func revealed(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0).offset(y: isVisible ? 0 : 8)
    }
}
