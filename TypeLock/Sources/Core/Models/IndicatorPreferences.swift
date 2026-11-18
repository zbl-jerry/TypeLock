import Foundation

enum IndicatorDuration: Double, CaseIterable, Codable, Identifiable, Sendable {
    case oneSecond = 1
    case twoSeconds = 2
    case threeSeconds = 3
    case fiveSeconds = 5

    var id: Double { rawValue }
}

enum IndicatorPosition: String, CaseIterable, Codable, Identifiable, Sendable {
    case screen
    case mouse

    var id: String { rawValue }
}

enum IndicatorCursorPosition: String, CaseIterable, Codable, Identifiable, Sendable {
    case above
    case below
    case right

    var id: String { rawValue }
}

enum IndicatorStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case iconAndTitle
    case iconOnly
    case titleOnly

    var id: String { rawValue }
}

enum IndicatorSize: String, CaseIterable, Codable, Identifiable, Sendable {
    case normal
    case medium
    case large

    var id: String { rawValue }
}

struct IndicatorPreferences: Codable, Hashable, Sendable {
    var v: Int
    var enabled: Bool
    var onlyOnChange: Bool
    var preferCursor: Bool
    var onlyAtCursor: Bool
    var duration: IndicatorDuration
    var position: IndicatorPosition
    var cursorPosition: IndicatorCursorPosition
    var style: IndicatorStyle
    var size: IndicatorSize

    init(
        v: Int = MigrationVersion.current,
        enabled: Bool = true,
        onlyOnChange: Bool = true,
        preferCursor: Bool = true,
        onlyAtCursor: Bool = false,
        duration: IndicatorDuration = .oneSecond,
        position: IndicatorPosition = .screen,
        cursorPosition: IndicatorCursorPosition = .above,
        style: IndicatorStyle = .iconAndTitle,
        size: IndicatorSize = .normal
    ) {
        self.v = v
        self.enabled = enabled
        self.onlyOnChange = onlyOnChange
        self.preferCursor = preferCursor
        self.onlyAtCursor = onlyAtCursor
        self.duration = duration
        self.position = position
        self.cursorPosition = cursorPosition
        self.style = style
        self.size = size
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
