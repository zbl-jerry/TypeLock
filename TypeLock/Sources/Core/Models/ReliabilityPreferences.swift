import Foundation

struct ReliabilityPreferences: Codable, Hashable, Sendable {
    var v: Int
    var cjkvFixEnabled: Bool
    var cursorLagFixEnabled: Bool

    init(
        v: Int = MigrationVersion.current,
        cjkvFixEnabled: Bool = false,
        cursorLagFixEnabled: Bool = false
    ) {
        self.v = v
        self.cjkvFixEnabled = cjkvFixEnabled
        self.cursorLagFixEnabled = cursorLagFixEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case v
        case cjkvFixEnabled
        case cursorLagFixEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        v = try container.decodeIfPresent(Int.self, forKey: .v) ?? MigrationVersion.current
        cjkvFixEnabled = try container.decodeIfPresent(Bool.self, forKey: .cjkvFixEnabled) ?? false
        cursorLagFixEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .cursorLagFixEnabled
        ) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(v, forKey: .v)
        try container.encode(cjkvFixEnabled, forKey: .cjkvFixEnabled)
        try container.encode(cursorLagFixEnabled, forKey: .cursorLagFixEnabled)
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
