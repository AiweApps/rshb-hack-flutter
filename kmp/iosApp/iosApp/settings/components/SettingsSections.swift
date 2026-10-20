import SwiftUI
import SharedLogic

struct SettingsAppearanceSection: View {
    let themeMode: ThemeMode
    let languageCode: String
    let onTheme: (ThemeMode) -> Void
    let onLanguage: () -> Void

    private static let themes: [ThemeMode] = [.system, .light, .dark]

    var body: some View {
        Section(String(localized: "settings_appearance")) {
            themeMenu
            SettingsRow(
                title: String(localized: "settings_language"),
                systemImage: "globe",
                value: LanguageLabel.name(for: languageCode),
                action: onLanguage
            )
        }
    }

    /// The three themes right on the row, the current one ticked.
    private var themeMenu: some View {
        Menu {
            Picker(String(localized: "settings_theme"), selection: Binding(
                get: { themeMode },
                set: { onTheme($0) }
            )) {
                ForEach(Self.themes, id: \.self) { mode in
                    Text(label(for: mode)).tag(mode)
                }
            }
        } label: {
            HStack {
                Label(String(localized: "settings_theme"), appSymbol: "circle.lefthalf.filled")
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 8)
                Text(label(for: themeMode)).foregroundStyle(Color.secondary)
                AppIcon(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.selection, trigger: themeMode)
    }

    private func label(for mode: ThemeMode) -> String {
        if mode == ThemeMode.light { return String(localized: "theme_light") }
        if mode == ThemeMode.dark { return String(localized: "theme_dark") }
        return String(localized: "theme_system")
    }
}

struct SettingsServiceSection: View {
    let serviceState: ServiceState
    let catalogCards: Int32?
    let onStatus: () -> Void

    @State private var tapCount = 0

    var body: some View {
        Section {
            Button {
                tapCount += 1
                onStatus()
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings_service"))
                                .foregroundStyle(Color.primary)
                            if let catalogCards {
                                Text(L10n.plural("settings_catalog_size", count: catalogCards))
                                    .font(.footnote)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    } icon: {
                        AppIcon(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(Color.primary)
                    }
                    Spacer(minLength: 8)
                    ServiceStatusLabel(state: serviceState)
                        .foregroundStyle(Color.secondary)
                }
                .contentShape(Rectangle())
            }
            .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        }
    }
}

struct SettingsHelpSection: View {
    let onShowOnboarding: () -> Void
    let onAbout: () -> Void
    let onOpenSite: () -> Void

    var body: some View {
        Section {
            SettingsRow(
                title: String(localized: "settings_show_onboarding"),
                systemImage: "sparkles",
                action: onShowOnboarding
            )
            SettingsRow(
                title: String(localized: "settings_about"),
                systemImage: "info.circle",
                action: onAbout
            )
            SettingsRow(
                title: String(localized: "settings_open_site"),
                systemImage: "safari",
                chevron: "arrow.up.right",
                action: onOpenSite
            )
        } header: {
            Text(String(localized: "settings_help"))
        } footer: {
            // The health warning and the age mark every alcohol-related app carries; here,
            // mid-screen, rather than under the version where nobody scrolls.
            HStack(alignment: .center, spacing: 12) {
                Text(String(localized: "settings_alcohol_warning"))
                Spacer(minLength: 0)
                Text(String(localized: "settings_age_limit"))
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(Capsule().stroke(AppTheme.muted, lineWidth: 1))
            }
        }
    }
}

struct SettingsDataSection: View {
    let isClearing: Bool
    let confirm: ConfirmClearHistoryComponent?
    let onClear: () -> Void
    let onConfirmDismiss: () -> Void

    var body: some View {
        Section(String(localized: "settings_data")) {
            SettingsRow(
                title: String(localized: "history_clear"),
                systemImage: "trash",
                role: .destructive,
                action: onClear
            ) {
                if isClearing {
                    ProgressView()
                }
            }
            .disabled(isClearing)
            // On the row, so the popover form of the dialog points at it.
            .confirmClearHistoryDialog(component: confirm, onDismiss: onConfirmDismiss)
        }
    }
}
