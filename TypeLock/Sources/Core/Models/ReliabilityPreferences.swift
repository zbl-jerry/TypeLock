import Foundation

struct ReliabilityPreferences: Codable, Hashable, Sendable {
    var v: Int
    var cjkvFixEnabled: Bool

    init(
        v: Int = MigrationVersion.current,
        cjkvFixEnabled: Bool = false
    ) {
        self.v = v
        self.cjkvFixEnabled = cjkvFixEnabled
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
