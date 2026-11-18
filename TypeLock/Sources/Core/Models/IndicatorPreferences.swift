import CoreGraphics
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

enum IndicatorAlignment: String, CaseIterable, Codable, Identifiable, Sendable {
    case topLeft
    case topCenter
    case topRight
    case centerLeft
    case center
    case centerRight
    case bottomLeft
    case bottomCenter
    case bottomRight

    var id: String { rawValue }
}

enum IndicatorSpacing: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case xs
    case s
    case m
    case l
    case xl

    var id: String { rawValue }

    var points: CGFloat {
        switch self {
        case .none: 0
        case .xs: 4
        case .s: 8
        case .m: 12
        case .l: 18
        case .xl: 24
        }
    }
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
    var alignment: IndicatorAlignment
    var spacing: IndicatorSpacing
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
        alignment: IndicatorAlignment = .center,
        spacing: IndicatorSpacing = .s,
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
        self.alignment = alignment
        self.spacing = spacing
        self.style = style
        self.size = size
    }

    private enum CodingKeys: String, CodingKey {
        case v
        case enabled
        case onlyOnChange
        case preferCursor
        case onlyAtCursor
        case duration
        case position
        case cursorPosition
        case alignment
        case spacing
        case style
        case size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        v = try container.decodeIfPresent(Int.self, forKey: .v) ?? MigrationVersion.current
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        onlyOnChange = try container.decodeIfPresent(Bool.self, forKey: .onlyOnChange) ?? true
        preferCursor = try container.decodeIfPresent(Bool.self, forKey: .preferCursor) ?? true
        onlyAtCursor = try container.decodeIfPresent(Bool.self, forKey: .onlyAtCursor) ?? false
        duration = try container.decodeIfPresent(IndicatorDuration.self, forKey: .duration) ?? .oneSecond
        position = try container.decodeIfPresent(IndicatorPosition.self, forKey: .position) ?? .screen
        cursorPosition = try container.decodeIfPresent(
            IndicatorCursorPosition.self,
            forKey: .cursorPosition
        ) ?? .above
        alignment = try container.decodeIfPresent(IndicatorAlignment.self, forKey: .alignment) ?? .center
        spacing = try container.decodeIfPresent(IndicatorSpacing.self, forKey: .spacing) ?? .s
        style = try container.decodeIfPresent(IndicatorStyle.self, forKey: .style) ?? .iconAndTitle
        size = try container.decodeIfPresent(IndicatorSize.self, forKey: .size) ?? .normal
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(v, forKey: .v)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(onlyOnChange, forKey: .onlyOnChange)
        try container.encode(preferCursor, forKey: .preferCursor)
        try container.encode(onlyAtCursor, forKey: .onlyAtCursor)
        try container.encode(duration, forKey: .duration)
        try container.encode(position, forKey: .position)
        try container.encode(cursorPosition, forKey: .cursorPosition)
        try container.encode(alignment, forKey: .alignment)
        try container.encode(spacing, forKey: .spacing)
        try container.encode(style, forKey: .style)
        try container.encode(size, forKey: .size)
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
