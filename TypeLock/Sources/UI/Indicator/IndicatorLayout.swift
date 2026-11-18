import CoreGraphics

enum IndicatorLayout {
    static let caretGap: CGFloat = 8
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
                pointNearCaret(caret, size: size, position: preferences.cursorPosition),
                size: size,
                to: screenFrame
            )
        }

        if preferences.onlyAtCursor {
            return nil
        }

        switch preferences.position {
        case .screen:
            return CGPoint(
                x: screenFrame.midX - size.width / 2,
                y: screenFrame.midY - size.height / 2
            )
        case .mouse:
            return clamp(
                CGPoint(x: mouse.x + 12, y: mouse.y + 12),
                size: size,
                to: screenFrame
            )
        }
    }

    static func pointNearCaret(
        _ caret: CGRect,
        size: CGSize,
        position: IndicatorCursorPosition
    ) -> CGPoint {
        switch position {
        case .above:
            return CGPoint(
                x: caret.midX - size.width / 2,
                y: caret.maxY + caretGap
            )
        case .below:
            return CGPoint(
                x: caret.midX - size.width / 2,
                y: caret.minY - size.height - caretGap
            )
        case .right:
            return CGPoint(
                x: caret.maxX + caretGap,
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
