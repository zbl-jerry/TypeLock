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
    var launchStrategy: InputMethodStrategy

    init(
        v: Int = MigrationVersion.current,
        strategy: InputMethodStrategy = .none,
        launchStrategy: InputMethodStrategy = .none
    ) {
        self.v = v
        self.strategy = strategy
        self.launchStrategy = launchStrategy
    }

    private enum CodingKeys: String, CodingKey {
        case v
        case strategy
        case launchStrategy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        v = try container.decode(Int.self, forKey: .v)
        strategy = try container.decode(InputMethodStrategy.self, forKey: .strategy)
        launchStrategy = try container.decodeIfPresent(
            InputMethodStrategy.self,
            forKey: .launchStrategy
        ) ?? .none
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(v, forKey: .v)
        try container.encode(strategy, forKey: .strategy)
        try container.encode(launchStrategy, forKey: .launchStrategy)
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
