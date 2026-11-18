import SwiftUI

struct IndicatorView: View {
    let inputMethodName: String
    let style: IndicatorStyle
    let size: IndicatorSize

    var body: some View {
        HStack(spacing: 6) {
            if style != .titleOnly {
                Image(systemName: "keyboard")
            }
            if style != .iconOnly {
                Text(inputMethodName)
                    .lineLimit(1)
            }
        }
        .font(.system(size: fontSize, weight: .medium))
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.12))
        }
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
