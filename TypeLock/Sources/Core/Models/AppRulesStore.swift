import Foundation

struct AppRulesStore: Codable, Hashable, Sendable {
    var v: Int
    var rules: [String: AppRuleRecord]

    init(v: Int = MigrationVersion.current, rules: [String: AppRuleRecord] = [:]) {
        self.v = v
        self.rules = rules
    }

    mutating func upsertRecord(for appInfo: AppInfo, at date: Date) {
        guard var existingRule = rules[appInfo.bundleId] else {
            rules[appInfo.bundleId] = AppRuleRecord(
                bundleId: appInfo.bundleId,
                lastKnownPath: appInfo.path,
                lastKnownName: appInfo.name,
                strategy: .none,
                createdAt: date,
                updatedAt: date
            )
            return
        }

        guard existingRule.lastKnownPath != appInfo.path || existingRule.lastKnownName != appInfo.name else {
            return
        }

        existingRule.lastKnownPath = appInfo.path
        existingRule.lastKnownName = appInfo.name
        existingRule.updatedAt = date
        rules[appInfo.bundleId] = existingRule
    }

    /// Version 2 adds `launchStrategy`, which decodes as `.inherit` for legacy
    /// records. Bumping the stored version makes the upgrade explicit and
    /// prevents the migration from running again.
    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}

struct FallbackRuleStore: Codable, Hashable, Sendable {
    var v: Int
    var strategy: InputMethodStrategy

    init(v: Int = MigrationVersion.current, strategy: InputMethodStrategy = .none) {
        self.v = v
        self.strategy = strategy
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
