import AppKit
import Carbon
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
                    case .indicator:
                        IndicatorSettingsPane(store: store)
                    case .hotkeys:
                        HotkeysSettingsPane(store: store)
                    case .exclusions:
                        ExclusionsSettingsPane(store: store)
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
            ) as? String ?? "unknown",
            exclusionsStore: store.exclusions,
            indicatorPreferences: store.indicator,
            hotkeyPreferences: store.hotkeys
        )
    }

    private func makeCurrentPayload() -> SettingsImportPayload {
        SettingsImportPayload(
            appRulesStore: AppRulesStore(
                v: MigrationVersion.current,
                rules: store.appRules
            ),
            fallbackRuleStore: store.fallbackRule,
            appSwitchStatisticsStore: store.appSwitchStatistics,
            exclusionsStore: store.exclusions,
            indicatorPreferences: store.indicator,
            hotkeyPreferences: store.hotkeys
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

private struct HotkeysSettingsPane: View {
    let store: StoreOf<AppFeature>

    @StateObject private var recorder = HotkeyRecorder()
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.inputMethods.isEmpty {
                SettingsPlaceholderPane(section: .hotkeys)
            } else {
                ForEach(store.inputMethods) { inputMethod in
                    SettingsRow {
                        Text(inputMethod.name)
                        Spacer()
                        Text(shortcutDisplay(for: inputMethod.id))
                            .foregroundStyle(.secondary)
                        Button(recorder.recordingInputMethodId == inputMethod.id
                            ? "settings.hotkeys.recording"
                            : "settings.hotkeys.record") {
                            startRecording(for: inputMethod.id)
                        }
                        Button("settings.hotkeys.clear") {
                            var preferences = store.hotkeys
                            preferences.removeBinding(for: inputMethod.id)
                            store.send(.view(.setHotkeyPreferences(preferences)))
                            message = nil
                        }
                        .disabled(store.hotkeys.binding(for: inputMethod.id) == nil)
                    }
                }
            }

            if let message {
                SettingsHint {
                    Text(message)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .onDisappear {
            recorder.stop()
        }
    }

    private func startRecording(for inputMethodId: String) {
        message = nil
        recorder.start(inputMethodId: inputMethodId) { keyCode, modifiers in
            let candidate = HotkeyBinding(
                inputMethodId: inputMethodId,
                keyCode: keyCode,
                modifiers: modifiers
            )
            var preferences = store.hotkeys
            if preferences.conflicts(with: candidate) != nil {
                message = String(localized: "settings.hotkeys.conflict")
                return
            }
            preferences.setBinding(candidate)
            store.send(.view(.setHotkeyPreferences(preferences)))
        }
    }

    private func shortcutDisplay(for inputMethodId: String) -> String {
        guard let binding = store.hotkeys.binding(for: inputMethodId) else {
            return String(localized: "settings.hotkeys.none")
        }
        return HotkeyDisplay.string(keyCode: binding.keyCode, modifiers: binding.modifiers)
    }
}

@MainActor
private final class HotkeyRecorder: ObservableObject {
    @Published private(set) var recordingInputMethodId: String?
    private var monitor: Any?

    func start(inputMethodId: String, onCapture: @escaping (UInt32, UInt32) -> Void) {
        stop()
        recordingInputMethodId = inputMethodId
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            MainActor.assumeIsolated {
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let modifiers = HotkeyDisplay.carbonModifiers(flags)
                guard modifiers != 0 else { return event }

                onCapture(UInt32(event.keyCode), modifiers)
                self?.stop()
                return nil
            }
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        recordingInputMethodId = nil
    }
}

enum HotkeyDisplay {
    static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        return modifiers
    }

    static func string(keyCode: UInt32, modifiers: UInt32) -> String {
        var value = ""
        if modifiers & UInt32(controlKey) != 0 { value += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { value += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { value += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { value += "⌘" }
        value += keyName(for: keyCode)
        return value
    }

    static func keyName(for keyCode: UInt32) -> String {
        let names: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "Space",
            50: "`", 51: "⌫", 53: "⎋", 96: "F5", 97: "F6", 98: "F7",
            99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13",
            107: "F14", 109: "F10", 111: "F12", 113: "F15", 115: "↖",
            116: "⇞", 117: "⌦", 118: "F4", 119: "↘", 120: "F2",
            121: "⇟", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return names[keyCode] ?? "Key\(keyCode)"
    }
}

private struct IndicatorSettingsPane: View {
    let store: StoreOf<AppFeature>

    private func update(_ change: (inout IndicatorPreferences) -> Void) {
        var draft = store.indicator
        change(&draft)
        store.send(.view(.setIndicatorPreferences(draft)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsRow {
                Toggle("settings.indicator.enabled", isOn: Binding(
                    get: { store.indicator.enabled },
                    set: { value in update { $0.enabled = value } }
                ))
                .toggleStyle(.switch)
            }

            SettingsRow {
                Toggle("settings.indicator.only_on_change", isOn: Binding(
                    get: { store.indicator.onlyOnChange },
                    set: { value in update { $0.onlyOnChange = value } }
                ))
                .toggleStyle(.switch)
            }

            SettingsRow {
                Toggle("settings.indicator.prefer_cursor", isOn: Binding(
                    get: { store.indicator.preferCursor },
                    set: { value in update { $0.preferCursor = value } }
                ))
                .toggleStyle(.switch)
            }

            SettingsRow {
                Toggle("settings.indicator.only_at_cursor", isOn: Binding(
                    get: { store.indicator.onlyAtCursor },
                    set: { value in update { $0.onlyAtCursor = value } }
                ))
                .toggleStyle(.switch)
            }

            SettingsRow {
                Picker("settings.indicator.duration", selection: Binding(
                    get: { store.indicator.duration },
                    set: { value in update { $0.duration = value } }
                )) {
                    ForEach(IndicatorDuration.allCases) { duration in
                        Text("\(Int(duration.rawValue))s").tag(duration)
                    }
                }
                .pickerStyle(.segmented)
            }

            SettingsRow {
                Picker("settings.indicator.position", selection: Binding(
                    get: { store.indicator.position },
                    set: { value in update { $0.position = value } }
                )) {
                    Text("settings.indicator.position.screen").tag(IndicatorPosition.screen)
                    Text("settings.indicator.position.mouse").tag(IndicatorPosition.mouse)
                }
                .pickerStyle(.segmented)
            }

            SettingsRow {
                Picker("settings.indicator.cursor_position", selection: Binding(
                    get: { store.indicator.cursorPosition },
                    set: { value in update { $0.cursorPosition = value } }
                )) {
                    Text("settings.indicator.cursor.above").tag(IndicatorCursorPosition.above)
                    Text("settings.indicator.cursor.below").tag(IndicatorCursorPosition.below)
                    Text("settings.indicator.cursor.right").tag(IndicatorCursorPosition.right)
                }
                .pickerStyle(.segmented)
            }

            SettingsRow {
                Picker("settings.indicator.style", selection: Binding(
                    get: { store.indicator.style },
                    set: { value in update { $0.style = value } }
                )) {
                    Text("settings.indicator.style.icon_and_title").tag(IndicatorStyle.iconAndTitle)
                    Text("settings.indicator.style.icon_only").tag(IndicatorStyle.iconOnly)
                    Text("settings.indicator.style.title_only").tag(IndicatorStyle.titleOnly)
                }
                .pickerStyle(.segmented)
            }

            SettingsRow {
                Picker("settings.indicator.size", selection: Binding(
                    get: { store.indicator.size },
                    set: { value in update { $0.size = value } }
                )) {
                    Text("settings.indicator.size.normal").tag(IndicatorSize.normal)
                    Text("settings.indicator.size.medium").tag(IndicatorSize.medium)
                    Text("settings.indicator.size.large").tag(IndicatorSize.large)
                }
                .pickerStyle(.segmented)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ExclusionsSettingsPane: View {
    let store: StoreOf<AppFeature>

    private var rules: [AppRuleRecord] {
        store.appRules.values.sorted {
            $0.lastKnownName.localizedStandardCompare($1.lastKnownName) == .orderedAscending
        }
    }

    private var switchingBundleIds: [String] {
        let ignored = store.appRules.values
            .filter { $0.strategy == .ignored }
            .map(\.bundleId)
        return Array(store.exclusions.switchingBundleIds.union(ignored)).sorted()
    }

    private var indicatorBundleIds: [String] {
        Array(store.exclusions.indicatorBundleIds).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ExclusionSection(
                title: "settings.exclusions.switching",
                bundleIds: switchingBundleIds,
                rules: rules,
                onAdd: { bundleId in
                    store.send(.view(.setSwitchingExclusion(bundleId: bundleId, excluded: true)))
                },
                onRemove: { bundleId in
                    if store.appRules[bundleId]?.strategy == .ignored {
                        store.send(.view(.restoreIgnoredAppTapped(bundleId: bundleId)))
                    } else {
                        store.send(.view(.setSwitchingExclusion(bundleId: bundleId, excluded: false)))
                    }
                }
            )

            ExclusionSection(
                title: "settings.exclusions.indicator",
                bundleIds: indicatorBundleIds,
                rules: rules,
                onAdd: { bundleId in
                    store.send(.view(.setIndicatorExclusion(bundleId: bundleId, excluded: true)))
                },
                onRemove: { bundleId in
                    store.send(.view(.setIndicatorExclusion(bundleId: bundleId, excluded: false)))
                }
            )
        }
    }
}

private struct ExclusionSection: View {
    let title: LocalizedStringKey
    let bundleIds: [String]
    let rules: [AppRuleRecord]
    let onAdd: (String) -> Void
    let onRemove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Menu("settings.exclusions.add") {
                    ForEach(rules) { rule in
                        Button(rule.lastKnownName) {
                            onAdd(rule.bundleId)
                        }
                    }
                }
                .disabled(rules.isEmpty)
            }
            .padding()

            if bundleIds.isEmpty {
                Text("settings.exclusions.empty")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            } else {
                ForEach(bundleIds, id: \.self) { bundleId in
                    HStack {
                        Text(name(for: bundleId))
                        Text(bundleId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("settings.exclusions.remove") {
                            onRemove(bundleId)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    private func name(for bundleId: String) -> String {
        rules.first(where: { $0.bundleId == bundleId })?.lastKnownName ?? bundleId
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
