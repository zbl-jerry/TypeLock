import Foundation

enum SettingsBackupError: Error, Equatable, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case mismatchedBundleId(key: String, recordBundleId: String)
    case invalidActivationFallback
    case invalidLaunchFallback

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Unsupported settings backup version \(version)."
        case let .mismatchedBundleId(key, recordBundleId):
            return "App rule key \(key) does not match bundle id \(recordBundleId)."
        case .invalidActivationFallback:
            return "The activation fallback must be no-switch or a fixed input method."
        case .invalidLaunchFallback:
            return "The launch fallback must be no-switch, fixed, or follow-last."
        }
    }
}

enum SettingsImportMode: Equatable, Sendable {
    case replace
    case merge
}

struct SettingsImportPayload: Equatable, Sendable {
    let appRulesStore: AppRulesStore
    let fallbackRuleStore: FallbackRuleStore
    let appSwitchStatisticsStore: AppSwitchStatisticsStore
    let exclusionsStore: ExclusionsStore
    let indicatorPreferences: IndicatorPreferences
    let hotkeyPreferences: HotkeyPreferences
    let browserRulesStore: BrowserRulesStore

    init(
        appRulesStore: AppRulesStore,
        fallbackRuleStore: FallbackRuleStore,
        appSwitchStatisticsStore: AppSwitchStatisticsStore,
        exclusionsStore: ExclusionsStore = ExclusionsStore(),
        indicatorPreferences: IndicatorPreferences = IndicatorPreferences(),
        hotkeyPreferences: HotkeyPreferences = HotkeyPreferences(),
        browserRulesStore: BrowserRulesStore = BrowserRulesStore()
    ) {
        self.appRulesStore = appRulesStore
        self.fallbackRuleStore = fallbackRuleStore
        self.appSwitchStatisticsStore = appSwitchStatisticsStore
        self.exclusionsStore = exclusionsStore
        self.indicatorPreferences = indicatorPreferences
        self.hotkeyPreferences = hotkeyPreferences
        self.browserRulesStore = browserRulesStore
    }
}

struct SettingsBackup: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportedAt: Date
    let appVersion: String
    let buildVersion: String
    let appRules: [String: AppRuleRecord]
    let fallbackRule: FallbackRuleStore
    let statistics: [String: Int]?
    let exclusions: ExclusionsStore?
    let indicatorPreferences: IndicatorPreferences?
    let hotkeys: HotkeyPreferences?
    let browserRules: BrowserRulesStore?

    init(
        appRulesStore: AppRulesStore,
        fallbackRuleStore: FallbackRuleStore,
        statistics: AppSwitchStatisticsStore,
        appVersion: String,
        buildVersion: String,
        exportedAt: Date = Date(),
        includeStatistics: Bool = false,
        exclusionsStore: ExclusionsStore? = nil,
        indicatorPreferences: IndicatorPreferences? = nil,
        hotkeyPreferences: HotkeyPreferences? = nil,
        browserRulesStore: BrowserRulesStore? = nil
    ) {
        schemaVersion = Self.currentSchemaVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.buildVersion = buildVersion
        appRules = appRulesStore.rules
        fallbackRule = fallbackRuleStore
        self.statistics = includeStatistics ? statistics.counts : nil
        exclusions = exclusionsStore
        self.indicatorPreferences = indicatorPreferences
        hotkeys = hotkeyPreferences
        browserRules = browserRulesStore
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw SettingsBackupError.unsupportedSchemaVersion(schemaVersion)
        }

        for (key, rule) in appRules where key != rule.bundleId {
            throw SettingsBackupError.mismatchedBundleId(
                key: key,
                recordBundleId: rule.bundleId
            )
        }

        switch fallbackRule.strategy {
        case .none, .fixed:
            break
        case .followLast, .ignored:
            throw SettingsBackupError.invalidActivationFallback
        }

        switch fallbackRule.launchStrategy {
        case .none, .fixed, .followLast:
            break
        case .ignored:
            throw SettingsBackupError.invalidLaunchFallback
        }
    }

    func payload(
        mode: SettingsImportMode,
        current: SettingsImportPayload
    ) throws -> SettingsImportPayload {
        try validate()

        let importedRules = appRules
        let importedFallback = FallbackRuleStore(
            v: MigrationVersion.current,
            strategy: fallbackRule.strategy,
            launchStrategy: fallbackRule.launchStrategy
        )
        let importedStatistics = statistics ?? current.appSwitchStatisticsStore.counts
        let importedExclusions = exclusions ?? current.exclusionsStore
        let importedIndicator = indicatorPreferences ?? current.indicatorPreferences
        let importedHotkeys = hotkeys ?? current.hotkeyPreferences
        let importedBrowserRules = browserRules ?? current.browserRulesStore

        switch mode {
        case .replace:
            return SettingsImportPayload(
                appRulesStore: AppRulesStore(
                    v: MigrationVersion.current,
                    rules: importedRules
                ),
                fallbackRuleStore: importedFallback,
                appSwitchStatisticsStore: AppSwitchStatisticsStore(
                    counts: importedStatistics
                ),
                exclusionsStore: importedExclusions,
                indicatorPreferences: importedIndicator,
                hotkeyPreferences: importedHotkeys,
                browserRulesStore: importedBrowserRules
            )
        case .merge:
            var mergedRules = current.appRulesStore.rules
            for (bundleId, rule) in importedRules {
                mergedRules[bundleId] = rule
            }

            var mergedStatistics = current.appSwitchStatisticsStore.counts
            for (bundleId, count) in importedStatistics {
                mergedStatistics[bundleId] = count
            }

            var mergedExclusions = current.exclusionsStore
            mergedExclusions.switchingBundleIds.formUnion(importedExclusions.switchingBundleIds)
            mergedExclusions.indicatorBundleIds.formUnion(importedExclusions.indicatorBundleIds)

            var mergedBrowserRules = current.browserRulesStore
            for rule in importedBrowserRules.rules {
                mergedBrowserRules.upsert(rule)
            }

            return SettingsImportPayload(
                appRulesStore: AppRulesStore(
                    v: MigrationVersion.current,
                    rules: mergedRules
                ),
                fallbackRuleStore: importedFallback,
                appSwitchStatisticsStore: AppSwitchStatisticsStore(
                    counts: mergedStatistics
                ),
                exclusionsStore: mergedExclusions,
                indicatorPreferences: importedIndicator,
                hotkeyPreferences: importedHotkeys,
                browserRulesStore: mergedBrowserRules
            )
        }
    }
}

enum SettingsBackupService {
    static func encode(_ backup: SettingsBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> SettingsBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(SettingsBackup.self, from: data)
        try backup.validate()
        return backup
    }

    static func write(_ backup: SettingsBackup, to url: URL) throws {
        let data = try encode(backup)
        try data.write(to: url, options: .atomic)
    }

    static func read(from url: URL) throws -> SettingsBackup {
        try decode(Data(contentsOf: url))
    }
}
