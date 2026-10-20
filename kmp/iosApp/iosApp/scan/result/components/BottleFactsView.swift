import SwiftUI
import SharedLogic

/// «About the wine», «Food pairings» and the catalogue link. Colour, sugar, serving
/// temperature and pairings come from the gastronomy catalogue and load beside the card:
/// while they are on their way they show a placeholder, and once in, a missing value says
/// «No data» rather than disappearing.
struct BottleFactsView: View {
    let card: WineCard
    /// `nil` while the gastronomy is loading.
    let facts: WineFacts?
    /// The loader is still working; `facts == nil` with this off means nothing arrived.
    let isLoading: Bool
    let loadError: AppError?
    let onRetry: () -> Void
    let onLinkTap: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDescriptionExpanded = false

    /// What to render: `nil` only while something is still on its way.
    private var resolved: WineFacts? {
        facts ?? (isLoading ? nil : WineFacts.companion.NO_DATA)
    }

    var body: some View {
        let facts = resolved
        let isPending = facts == nil
        VStack(alignment: .leading, spacing: 22) {
            if let loadError {
                errorRow(loadError)
            }
            GroupedSection(title: String(localized: "result_gastronomy")) {
                HStack(spacing: 12) {
                    AppIcon(systemName: "fork.knife")
                        .foregroundStyle(AppTheme.wine)
                        .accessibilityHidden(true)
                    pairings(facts)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                Text(String(localized: "result_by_card"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            GroupedSection(title: String(localized: "result_about")) {
                fact(
                    "compare_attr_color",
                    facts.flatMap { GastronomyText.color($0.color, isSparkling: $0.isSparkling?.boolValue) },
                    isLoading: isPending,
                    isUnavailable: loadError != nil
                )
                fact("compare_attr_sugar", facts.flatMap { GastronomyText.sugar($0.sugar) }, isLoading: isPending,
                     isUnavailable: loadError != nil)
                if let alcohol = card.validAlcohol?.doubleValue {
                    fact("compare_attr_alcohol", (alcohol / 100).formatted(.percent.precision(.fractionLength(0...2))),
                         isLoading: false)
                }
                fact("compare_attr_grapes", card.grapes, isLoading: false)
                fact("compare_attr_region", card.region, isLoading: false)
                fact(
                    "compare_attr_temperature",
                    facts?.servingTemperature.map(GastronomyText.temperature),
                    isLoading: isPending,
                    isUnavailable: loadError != nil
                )
            }
            description
            GroupedSection {
                link
            }
        }
        .onChange(of: card.slug) { _, _ in isDescriptionExpanded = false }
    }

    @ViewBuilder
    private var description: some View {
        if let text = card.description_, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "wine_description"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink2)
                    .lineLimit(isDescriptionExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(String(localized: isDescriptionExpanded ? "compare_hide_description" : "compare_show_description"))
                        AppIcon(systemName: isDescriptionExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.wine)
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func pairings(_ facts: WineFacts?) -> some View {
        if let facts {
            if let dishes = facts.pairings {
                if dishes.isEmpty {
                    Text(String(localized: "gastro_none_listed")).foregroundStyle(AppTheme.muted)
                } else {
                    Text(dishes.map(\.label).joined(separator: " · ")).foregroundStyle(AppTheme.ink)
                }
            } else {
                Text(String(localized: loadError == nil ? "common_no_data" : "gastro_unavailable"))
                    .foregroundStyle(AppTheme.muted)
            }
        } else {
            Text(String(repeating: "x", count: 28))
                .lineLimit(1)
                .loadingPlaceholder()
        }
    }

    private func errorRow(_ error: AppError) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "gastro_load_failed"))
                    .font(.subheadline.weight(.medium))
                Text(AppErrorText.message(for: error))
                    .font(.footnote)
            }
            .foregroundStyle(AppTheme.ink2)
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onRetry) {
                Group {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(String(localized: "common_retry"))
                            .font(.subheadline.weight(.medium))
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.wine)
            .disabled(isLoading)
        }
        .padding(12)
        .background(AppTheme.paper2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var link: some View {
        if let url = card.catalogueUrl {
            Button {
                onLinkTap(url)
            } label: {
                CatalogueLinkLabel(title: String(localized: "common_open_catalogue"))
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.wine)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
        } else {
            Text(String(localized: "result_no_site_url"))
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    /// A row of the «About» block: a placeholder while loading, else the value or «No data».
    private func fact(_ key: String, _ value: String?, isLoading: Bool, isUnavailable: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(L10n.string(key))
                .foregroundStyle(AppTheme.ink2)
            Spacer(minLength: 8)
            if isLoading {
                Text(String(repeating: "x", count: 9)).loadingPlaceholder()
            } else if let value, !value.isEmpty {
                Text(value).foregroundStyle(AppTheme.ink)
            } else {
                Text(String(localized: isUnavailable ? "gastro_unavailable" : "common_no_data"))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .multilineTextAlignment(.trailing)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
