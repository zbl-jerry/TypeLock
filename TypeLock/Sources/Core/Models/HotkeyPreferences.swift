import Foundation

struct HotkeyBinding: Codable, Hashable, Identifiable, Sendable {
    var inputMethodId: String
    var keyCode: UInt32
    var modifiers: UInt32

    var id: String { inputMethodId }
}

struct HotkeyPreferences: Codable, Hashable, Sendable {
    var v: Int
    var bindings: [String: HotkeyBinding]

    init(v: Int = MigrationVersion.current, bindings: [String: HotkeyBinding] = [:]) {
        self.v = v
        self.bindings = bindings
    }

    func binding(for inputMethodId: String) -> HotkeyBinding? {
        bindings[inputMethodId]
    }

    mutating func setBinding(_ binding: HotkeyBinding?) {
        guard let binding else { return }
        bindings[binding.inputMethodId] = binding
    }

    mutating func removeBinding(for inputMethodId: String) {
        bindings.removeValue(forKey: inputMethodId)
    }

    func conflicts(with candidate: HotkeyBinding) -> HotkeyBinding? {
        bindings.values.first {
            $0.inputMethodId != candidate.inputMethodId
                && $0.keyCode == candidate.keyCode
                && $0.modifiers == candidate.modifiers
        }
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
