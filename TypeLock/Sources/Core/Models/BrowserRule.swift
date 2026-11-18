import Foundation

enum BrowserRuleMatchType: String, Codable, CaseIterable, Identifiable, Sendable {
    case domain
    case domainSuffix
    case urlRegex

    var id: String { rawValue }
}

struct BrowserRule: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var matchType: BrowserRuleMatchType
    var pattern: String
    var inputMethodId: String
    var enabled: Bool
    var hideIndicator: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        matchType: BrowserRuleMatchType = .domainSuffix,
        pattern: String = "",
        inputMethodId: String,
        enabled: Bool = true,
        hideIndicator: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.matchType = matchType
        self.pattern = pattern
        self.inputMethodId = inputMethodId
        self.enabled = enabled
        self.hideIndicator = hideIndicator
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct BrowserRulesStore: Codable, Hashable, Sendable {
    var v: Int
    var rules: [BrowserRule]

    init(v: Int = MigrationVersion.current, rules: [BrowserRule] = []) {
        self.v = v
        self.rules = rules
    }

    mutating func upsert(_ rule: BrowserRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
    }

    mutating func remove(id: UUID) {
        rules.removeAll { $0.id == id }
    }

    func rule(id: UUID) -> BrowserRule? {
        rules.first { $0.id == id }
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}

enum BrowserRuleMatcher {
    static let maximumPatternLength = 512

    static func firstMatch(in rules: [BrowserRule], url: URL) -> BrowserRule? {
        rules.first { rule in
            rule.enabled && matches(rule, url: url)
        }
    }

    static func matches(_ rule: BrowserRule, url: URL) -> Bool {
        guard validate(rule) == nil else { return false }

        switch rule.matchType {
        case .domain:
            guard let domain = normalizedDomain(rule.pattern),
                  let host = normalizedDomain(url.host)
            else { return false }
            return host == domain
        case .domainSuffix:
            guard let suffix = normalizedDomain(rule.pattern),
                  let host = normalizedDomain(url.host)
            else { return false }
            return host == suffix || host.hasSuffix(".\(suffix)")
        case .urlRegex:
            guard let regex = try? NSRegularExpression(
                pattern: rule.pattern,
                options: .caseInsensitive
            ) else { return false }
            return regex.firstMatch(
                in: url.absoluteString,
                range: NSRange(url.absoluteString.startIndex..., in: url.absoluteString)
            ) != nil
        }
    }

    static func validate(_ rule: BrowserRule) -> String? {
        switch rule.matchType {
        case .domain, .domainSuffix:
            return normalizedDomain(rule.pattern) == nil ? "invalid-domain" : nil
        case .urlRegex:
            guard !rule.pattern.isEmpty,
                  rule.pattern.count <= maximumPatternLength
            else {
                return "invalid-regex"
            }
            return (try? NSRegularExpression(pattern: rule.pattern)) == nil
                ? "invalid-regex"
                : nil
        }
    }

    static func normalizedDomain(_ value: String?) -> String? {
        let domain = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()

        guard let domain, !domain.isEmpty else { return nil }
        return domain
    }
}
