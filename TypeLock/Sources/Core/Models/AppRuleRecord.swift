import Foundation

struct AppRuleRecord: Identifiable, Codable, Hashable, Sendable {
    let bundleId: String
    var lastKnownPath: String?
    var lastKnownName: String
    var strategy: InputMethodStrategy
    var strategyBeforeIgnoring: InputMethodStrategy?
    var launchStrategy: AppLaunchStrategy
    var createdAt: Date
    var updatedAt: Date

    var id: String { bundleId }

    /// The strategy applied when an app returns to the foreground.
    ///
    /// The persisted `strategy` key is kept for backward compatibility with
    /// existing TypeLock/TypeSwitch stores.
    var activationStrategy: InputMethodStrategy {
        get { strategy }
        set { strategy = newValue }
    }

    init(
        bundleId: String,
        lastKnownPath: String? = nil,
        lastKnownName: String,
        strategy: InputMethodStrategy,
        strategyBeforeIgnoring: InputMethodStrategy? = nil,
        launchStrategy: AppLaunchStrategy = .inherit,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.bundleId = bundleId
        self.lastKnownPath = lastKnownPath
        self.lastKnownName = lastKnownName
        self.strategy = strategy
        self.strategyBeforeIgnoring = strategyBeforeIgnoring
        self.launchStrategy = launchStrategy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case bundleId
        case lastKnownPath
        case lastKnownName
        case strategy
        case strategyBeforeIgnoring
        case launchStrategy
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        bundleId = try container.decode(String.self, forKey: .bundleId)
        lastKnownPath = try container.decodeIfPresent(String.self, forKey: .lastKnownPath)
        lastKnownName = try container.decode(String.self, forKey: .lastKnownName)
        strategy = try container.decode(InputMethodStrategy.self, forKey: .strategy)
        strategyBeforeIgnoring = try container.decodeIfPresent(
            InputMethodStrategy.self,
            forKey: .strategyBeforeIgnoring
        )
        launchStrategy = try container.decodeIfPresent(
            AppLaunchStrategy.self,
            forKey: .launchStrategy
        ) ?? .inherit
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(bundleId, forKey: .bundleId)
        try container.encodeIfPresent(lastKnownPath, forKey: .lastKnownPath)
        try container.encode(lastKnownName, forKey: .lastKnownName)
        try container.encode(strategy, forKey: .strategy)
        try container.encodeIfPresent(strategyBeforeIgnoring, forKey: .strategyBeforeIgnoring)
        try container.encode(launchStrategy, forKey: .launchStrategy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
