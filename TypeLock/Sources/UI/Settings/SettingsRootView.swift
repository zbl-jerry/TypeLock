import AppKit
import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

/// Phase 0 settings window shell.
///
/// The navigation and section boundaries are final; feature panes land in
/// later phases. General and Troubleshooting already surface working values.
struct SettingsRootView: View {
    let store: StoreOf<AppFeature>

    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.titleKey, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader(selection ?? .general)

                    switch selection ?? .general {
                    case .general:
                        GeneralSettingsPane(store: store)
                    case .apps:
                        AppRulesSettingsPane(store: store)
                    case .troubleshooting:
                        TroubleshootingSettingsPane()
                    case .about:
                        AboutSettingsPane()
                    default:
                        SettingsPlaceholderPane(section: selection ?? .general)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 760, minHeight: 520)
    }

    private func sectionHeader(_ section: SettingsSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(section.titleKey, systemImage: section.systemImage)
                .font(.title2.weight(.semibold))
            Text(section.summaryKey)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case apps
    case indicator
    case hotkeys
    case browser
    case terminal
    case exclusions
    case troubleshooting
    case about

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .general: "settings.section.general"
        case .apps: "settings.section.apps"
        case .indicator: "settings.section.indicator"
        case .hotkeys: "settings.section.hotkeys"
        case .browser: "settings.section.browser"
        case .terminal: "settings.section.terminal"
        case .exclusions: "settings.section.exclusions"
        case .troubleshooting: "settings.section.troubleshooting"
        case .about: "settings.section.about"
        }
    }

    var summaryKey: LocalizedStringKey {
        switch self {
        case .general: "settings.section.general.summary"
        case .apps: "settings.section.apps.summary"
        case .indicator: "settings.section.indicator.summary"
        case .hotkeys: "settings.section.hotkeys.summary"
        case .browser: "settings.section.browser.summary"
        case .terminal: "settings.section.terminal.summary"
        case .exclusions: "settings.section.exclusions.summary"
        case .troubleshooting: "settings.section.troubleshooting.summary"
        case .about: "settings.section.about.summary"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .apps: "app.badge"
        case .indicator: "text.bubble"
        case .hotkeys: "keyboard"
        case .browser: "safari"
        case .terminal: "terminal"
        case .exclusions: "eye.slash"
        case .troubleshooting: "wrench.and.screwdriver"
        case .about: "info.circle"
        }
    }
}

private struct GeneralSettingsPane: View {
    let store: StoreOf<AppFeature>

    @State private var backupMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsRow {
                Toggle(
                    "settings.general.auto_launch",
                    isOn: Binding(
                        get: { store.launchAtLoginEnabled },
                        set: { store.send(.view(.setLaunchAtLogin($0))) }
                    )
                )
                .toggleStyle(.switch)
            }

            if store.launchAtLoginRequiresApproval {
                SettingsHint {
                    Text("settings.general.auto_launch_requires_approval")
                    Button("settings.general.open_login_items") {
                        PermissionService.openLoginItemsSettings()
                    }
                }
            }

            SettingsRow {
                Text("settings.general.launch_input_method")
                Spacer()
                Text(store.fallbackLaunchSelectedLabel ?? String(localized: "settings.general.fallback_rule.none"))
                    .foregroundStyle(.secondary)
            }

            SettingsRow {
                Text("settings.general.fallback_rule")
                Spacer()
                Text(store.fallbackSelectedLabel ?? String(localized: "settings.general.fallback_rule.none"))
                    .foregroundStyle(.secondary)
            }

            SettingsRow {
                Text("settings.general.app_rules_count")
                Spacer()
                Text("\(store.appRules.count)")
                    .foregroundStyle(.secondary)
            }

            SettingsRow {
                Text("settings.general.data_version")
                Spacer()
                Text("\(MigrationVersion.current)")
                    .foregroundStyle(.secondary)
            }

            SettingsRow {
                Text("settings.backup.title")
                Spacer()
                Button("settings.backup.export") {
                    exportSettings()
                }
                Button("settings.backup.import") {
                    importSettings()
                }
            }

            if let backupMessage {
                SettingsHint {
                    Text(backupMessage)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func exportSettings() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "TypeLock-Config.json"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try SettingsBackupService.write(makeBackup(), to: url)
            backupMessage = String(localized: "settings.backup.exported")
        } catch {
            presentError(title: String(localized: "settings.backup.export_failed"), error: error)
        }
    }

    @MainActor
    private func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let backup = try SettingsBackupService.read(from: url)
            guard let mode = chooseImportMode() else { return }
            let payload = try backup.payload(mode: mode, current: makeCurrentPayload())
            store.send(.view(.applySettingsImport(payload)))
            backupMessage = String(localized: "settings.backup.imported")
        } catch {
            presentError(title: String(localized: "settings.backup.import_failed"), error: error)
        }
    }

    @MainActor
    private func chooseImportMode() -> SettingsImportMode? {
        let alert = NSAlert()
        alert.messageText = String(localized: "settings.backup.import_title")
        alert.informativeText = String(localized: "settings.backup.import_message")
        alert.addButton(withTitle: String(localized: "settings.backup.merge"))
        alert.addButton(withTitle: String(localized: "settings.backup.replace"))
        alert.addButton(withTitle: String(localized: "settings.backup.cancel"))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .merge
        case .alertSecondButtonReturn:
            return .replace
        default:
            return nil
        }
    }

    @MainActor
    private func presentError(title: String, error: Error) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func makeBackup() -> SettingsBackup {
        SettingsBackup(
            appRulesStore: AppRulesStore(
                v: MigrationVersion.current,
                rules: store.appRules
            ),
            fallbackRuleStore: store.fallbackRule,
            statistics: store.appSwitchStatistics,
            appVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "unknown",
            buildVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String ?? "unknown"
        )
    }

    private func makeCurrentPayload() -> SettingsImportPayload {
        SettingsImportPayload(
            appRulesStore: AppRulesStore(
                v: MigrationVersion.current,
                rules: store.appRules
            ),
            fallbackRuleStore: store.fallbackRule,
            appSwitchStatisticsStore: store.appSwitchStatistics
        )
    }
}

private struct AppRulesSettingsPane: View {
    let store: StoreOf<AppFeature>

    private var sortedRules: [AppRuleRecord] {
        store.appRules.values.sorted {
            $0.lastKnownName.localizedStandardCompare($1.lastKnownName) == .orderedAscending
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if sortedRules.isEmpty {
                SettingsPlaceholderPane(section: .apps)
            } else {
                ForEach(sortedRules) { rule in
                    AppRuleSettingsRow(
                        rule: rule,
                        inputMethods: store.inputMethods,
                        onSetLaunchStrategy: { strategy in
                            store.send(.view(.setLaunchStrategy(
                                bundleId: rule.bundleId,
                                strategy: strategy
                            )))
                        },
                        onSetActivationStrategy: { strategy in
                            store.send(.view(.setStrategy(
                                bundleId: rule.bundleId,
                                strategy: strategy
                            )))
                        }
                    )
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct AppRuleSettingsRow: View {
    let rule: AppRuleRecord
    let inputMethods: [InputMethod]
    let onSetLaunchStrategy: (AppLaunchStrategy) -> Void
    let onSetActivationStrategy: (InputMethodStrategy) -> Void

    private var appInfo: AppInfo {
        AppInfo(
            bundleId: rule.bundleId,
            name: rule.lastKnownName,
            path: rule.lastKnownPath
        )
    }

    var body: some View {
        SettingsRow {
            HStack(spacing: 12) {
                appInfo.icon
                    .resizable()
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.lastKnownName)
                    Text(rule.bundleId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Menu {
                        LaunchStrategyMenuContent(
                            strategy: rule.launchStrategy,
                            inputMethods: inputMethods,
                            onSelect: onSetLaunchStrategy
                        )
                    } label: {
                        HStack(spacing: 6) {
                            Text("settings.apps.launch")
                            Text(launchTitle)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Menu {
                        ActivationStrategyMenuContent(
                            strategy: rule.strategy,
                            inputMethods: inputMethods,
                            onSelect: onSetActivationStrategy
                        )
                    } label: {
                        HStack(spacing: 6) {
                            Text("settings.apps.activation")
                            Text(activationTitle)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }

    private var launchTitle: String {
        switch rule.launchStrategy {
        case .inherit:
            return String(localized: "settings.apps.inherit_global")
        case .none:
            return String(localized: "settings.apps.no_switch")
        case .followLast:
            return String(localized: "input_method.follow_last_option")
        case let .fixed(inputMethodId):
            return inputMethods.first(where: { $0.id == inputMethodId })?.name ?? inputMethodId
        }
    }

    private var activationTitle: String {
        switch rule.strategy {
        case .none:
            return String(localized: "settings.apps.inherit_global")
        case .ignored:
            return String(localized: "settings.apps.ignored")
        case .followLast:
            return String(localized: "input_method.follow_last_option")
        case let .fixed(inputMethodId):
            return inputMethods.first(where: { $0.id == inputMethodId })?.name ?? inputMethodId
        }
    }
}

private struct LaunchStrategyMenuContent: View {
    let strategy: AppLaunchStrategy
    let inputMethods: [InputMethod]
    let onSelect: (AppLaunchStrategy) -> Void

    var body: some View {
        option("settings.apps.inherit_global", strategy: .inherit)
        option("settings.apps.no_switch", strategy: .none)
        option("input_method.follow_last_option", strategy: followLastStrategy)

        Divider()

        ForEach(inputMethods) { inputMethod in
            option(inputMethod.name, strategy: .fixed(inputMethodId: inputMethod.id))
        }
    }

    private var followLastStrategy: AppLaunchStrategy {
        if case let .followLast(lastInputMethodId) = strategy {
            return .followLast(lastInputMethodId: lastInputMethodId)
        }
        return .followLast(lastInputMethodId: nil)
    }

    private func option(_ title: String, strategy option: AppLaunchStrategy) -> some View {
        Toggle(isOn: Binding(
            get: { strategy == option },
            set: { isSelected in
                guard isSelected else { return }
                onSelect(option)
            }
        )) {
            Text(title)
        }
        .toggleStyle(.checkbox)
    }
}

private struct ActivationStrategyMenuContent: View {
    let strategy: InputMethodStrategy
    let inputMethods: [InputMethod]
    let onSelect: (InputMethodStrategy) -> Void

    var body: some View {
        option("settings.apps.inherit_global", strategy: .none)
        option("input_method.follow_last_option", strategy: followLastStrategy)

        Divider()

        ForEach(inputMethods) { inputMethod in
            option(inputMethod.name, strategy: .fixed(inputMethodId: inputMethod.id))
        }
    }

    private var followLastStrategy: InputMethodStrategy {
        if case let .followLast(lastInputMethodId) = strategy {
            return .followLast(lastInputMethodId: lastInputMethodId)
        }
        return .followLast(lastInputMethodId: nil)
    }

    private func option(_ title: String, strategy option: InputMethodStrategy) -> some View {
        Toggle(isOn: Binding(
            get: { strategy == option },
            set: { isSelected in
                guard isSelected else { return }
                onSelect(option)
            }
        )) {
            Text(title)
        }
        .toggleStyle(.checkbox)
    }
}

private struct TroubleshootingSettingsPane: View {
    @State private var accessibility = PermissionService.accessibilityStatus
    @State private var inputMonitoring = PermissionService.inputMonitoringStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PermissionRow(
                title: "settings.permissions.accessibility",
                status: accessibility,
                openSettings: PermissionService.openAccessibilitySettings,
                request: {
                    accessibility = PermissionService.requestAccessibility()
                }
            )

            PermissionRow(
                title: "settings.permissions.input_monitoring",
                status: inputMonitoring,
                openSettings: PermissionService.openInputMonitoringSettings,
                request: {
                    inputMonitoring = PermissionService.requestInputMonitoring()
                }
            )

            SettingsRow {
                Text("settings.permissions.terminal")
                Spacer()
                Text("settings.permissions.terminal.pending")
                    .foregroundStyle(.secondary)
            }

            SettingsRow {
                Button("settings.permissions.refresh") {
                    accessibility = PermissionService.accessibilityStatus
                    inputMonitoring = PermissionService.inputMonitoringStatus
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PermissionRow: View {
    let title: LocalizedStringKey
    let status: PermissionStatus
    let openSettings: @MainActor () -> Void
    let request: @MainActor () -> Void

    private var statusTitle: LocalizedStringKey {
        status == .granted ? "settings.permissions.granted" : "settings.permissions.denied"
    }

    var body: some View {
        SettingsRow {
            Text(title)
            Spacer()
            Text(statusTitle)
                .foregroundStyle(status == .granted ? Color.green : Color.orange)
            Button("settings.permissions.open") {
                openSettings()
            }
            Button("settings.permissions.request") {
                request()
            }
        }
    }
}

private struct AboutSettingsPane: View {
    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsRow {
                Text("settings.about.version")
                Spacer()
                Text(version)
                    .foregroundStyle(.secondary)
            }

            SettingsRow {
                Button("settings.about.project_homepage") {
                    AppInfoService.openGitHubRepository()
                }
                Spacer()
                Button("settings.about.report_issue") {
                    AppInfoService.openReportIssue()
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SettingsPlaceholderPane: View {
    let section: SettingsSection

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: section.systemImage)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            Text(section.titleKey)
                .font(.headline)
            Text("settings.placeholder.coming_soon")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct SettingsHint<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            content
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}
