import Foundation

struct TerminalRule: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var program: String
    var inputMethodId: String
    var enabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        program: String = "",
        inputMethodId: String,
        enabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.program = program
        self.inputMethodId = inputMethodId
        self.enabled = enabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func matches(program candidate: String) -> Bool {
        let rule = Self.normalized(program)
        let value = Self.normalized(candidate)
        guard !rule.isEmpty, !value.isEmpty else { return false }
        return rule == value
    }

    static func normalized(_ program: String) -> String {
        let trimmed = program.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.split(separator: "/").last.map(String.init) ?? trimmed
        return name.lowercased()
    }
}

struct TerminalRulesStore: Codable, Hashable, Sendable {
    var v: Int
    var rules: [TerminalRule]

    init(v: Int = MigrationVersion.current, rules: [TerminalRule] = []) {
        self.v = v
        self.rules = rules
    }

    mutating func upsert(_ rule: TerminalRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
    }

    mutating func remove(id: UUID) {
        rules.removeAll { $0.id == id }
    }

    func firstMatch(program: String) -> TerminalRule? {
        rules.first { $0.enabled && $0.matches(program: program) }
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
