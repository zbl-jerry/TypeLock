import SwiftUI

struct IndicatorView: View {
    let inputMethodName: String
    let style: IndicatorStyle
    let size: IndicatorSize
    let appearance: InputMethodAppearance?
    let capsLock: Bool

    var body: some View {
        HStack(spacing: 6) {
            if style != .titleOnly {
                Image(systemName: "keyboard")
            }
            if style != .iconOnly {
                Text(displayName)
                    .lineLimit(1)
            }
            if capsLock {
                Image(systemName: "capslock.fill")
                    .font(.caption)
            }
        }
        .font(.system(size: fontSize, weight: .medium))
        .foregroundStyle(textColor ?? Color.primary)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background {
            if let backgroundColor {
                Capsule().fill(backgroundColor)
            } else {
                Capsule().fill(.regularMaterial)
            }
        }
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.12))
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var displayName: String {
        if let label = appearance?.label?.trimmingCharacters(in: .whitespacesAndNewlines),
           !label.isEmpty
        {
            return label
        }
        return inputMethodName
    }

    private var accessibilityLabel: String {
        var value = inputMethodName
        if capsLock {
            value += ", Caps Lock"
        }
        return value
    }

    private var backgroundColor: Color? {
        Color(hex: appearance?.backgroundColorHex)
    }

    private var textColor: Color? {
        Color(hex: appearance?.textColorHex)
    }

    private var fontSize: CGFloat {
        switch size {
        case .normal: 13
        case .medium: 16
        case .large: 20
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .normal: 10
        case .medium: 14
        case .large: 18
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .normal: 6
        case .medium: 8
        case .large: 11
        }
    }
}

extension Color {
    init?(hex: String?) {
        guard let hex else { return nil }

        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return nil
        }

        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}
