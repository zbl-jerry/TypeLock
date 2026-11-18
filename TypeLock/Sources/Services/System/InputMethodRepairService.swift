import AppKit
import Foundation

/// Forces macOS to settle the selected input source by briefly focusing a
/// transparent window and then restoring the previous app.
@MainActor
enum InputMethodRepairService {
    static func settleFocus() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return }

        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.alphaValue = 0
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.makeKeyAndOrderFront(nil)
        window.orderOut(nil)

        if #available(macOS 14.0, *) {
            frontmost.activate()
        } else {
            frontmost.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
