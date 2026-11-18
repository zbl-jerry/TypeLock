import CoreGraphics

enum IndicatorLayout {
    static let edgePadding: CGFloat = 8

    static func origin(
        caret: CGRect?,
        size: CGSize,
        preferences: IndicatorPreferences,
        screenFrame: CGRect,
        mouse: CGPoint
    ) -> CGPoint? {
        if let caret, preferences.preferCursor || preferences.onlyAtCursor {
            return clamp(
                pointNearCaret(
                    caret,
                    size: size,
                    position: preferences.cursorPosition,
                    gap: preferences.spacing.points
                ),
                size: size,
                to: screenFrame
            )
        }

        if preferences.onlyAtCursor {
            return nil
        }

        switch preferences.position {
        case .screen:
            return screenPoint(
                frame: screenFrame,
                size: size,
                alignment: preferences.alignment,
                spacing: preferences.spacing.points
            )
        case .mouse:
            let offset = preferences.spacing.points + 4
            return clamp(
                CGPoint(x: mouse.x + offset, y: mouse.y + offset),
                size: size,
                to: screenFrame
            )
        }
    }

    static func screenPoint(
        frame: CGRect,
        size: CGSize,
        alignment: IndicatorAlignment,
        spacing: CGFloat
    ) -> CGPoint {
        let left = frame.minX + spacing
        let centerX = frame.midX - size.width / 2
        let right = frame.maxX - size.width - spacing
        let bottom = frame.minY + spacing
        let centerY = frame.midY - size.height / 2
        let top = frame.maxY - size.height - spacing

        switch alignment {
        case .topLeft:
            return CGPoint(x: left, y: top)
        case .topCenter:
            return CGPoint(x: centerX, y: top)
        case .topRight:
            return CGPoint(x: right, y: top)
        case .centerLeft:
            return CGPoint(x: left, y: centerY)
        case .center:
            return CGPoint(x: centerX, y: centerY)
        case .centerRight:
            return CGPoint(x: right, y: centerY)
        case .bottomLeft:
            return CGPoint(x: left, y: bottom)
        case .bottomCenter:
            return CGPoint(x: centerX, y: bottom)
        case .bottomRight:
            return CGPoint(x: right, y: bottom)
        }
    }

    static func pointNearCaret(
        _ caret: CGRect,
        size: CGSize,
        position: IndicatorCursorPosition,
        gap: CGFloat = 8
    ) -> CGPoint {
        switch position {
        case .above:
            return CGPoint(
                x: caret.midX - size.width / 2,
                y: caret.maxY + gap
            )
        case .below:
            return CGPoint(
                x: caret.midX - size.width / 2,
                y: caret.minY - size.height - gap
            )
        case .right:
            return CGPoint(
                x: caret.maxX + gap,
                y: caret.midY - size.height / 2
            )
        }
    }

    static func clamp(_ point: CGPoint, size: CGSize, to frame: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, frame.minX + edgePadding), frame.maxX - size.width - edgePadding),
            y: min(max(point.y, frame.minY + edgePadding), frame.maxY - size.height - edgePadding)
        )
    }
}
