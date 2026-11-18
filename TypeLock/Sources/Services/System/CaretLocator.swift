import AppKit
import ApplicationServices
import Foundation

/// Reads the focused text caret through the Accessibility API.
///
/// Returns nil when Accessibility is not granted or the focused element does
/// not expose bounds; callers fall back to mouse/screen placement.
@MainActor
enum CaretLocator {
    static func currentCaretRect() -> CGRect? {
        guard PermissionService.accessibilityStatus == .granted else { return nil }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        ) == .success,
            let focusedValue
        else {
            return nil
        }

        let focusedElement = focusedValue as! AXUIElement

        var positionValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focusedElement,
            kAXPositionAttribute as CFString,
            &positionValue
        ) == .success,
            let positionValue
        else {
            return nil
        }

        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSizeAttribute as CFString,
            &sizeValue
        ) == .success,
            let sizeValue
        else {
            return nil
        }

        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size),
              size.width > 0,
              size.height > 0
        else {
            return nil
        }

        return convertFromAccessibility(CGRect(origin: origin, size: size))
    }

    /// AX uses a top-left origin on the primary display; AppKit uses a
    /// bottom-left origin.
    static func convertFromAccessibility(_ rect: CGRect) -> CGRect {
        let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
            ?? NSScreen.screens.first
        let primaryMaxY = primary?.frame.maxY ?? rect.maxY

        return CGRect(
            x: rect.origin.x,
            y: primaryMaxY - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}
