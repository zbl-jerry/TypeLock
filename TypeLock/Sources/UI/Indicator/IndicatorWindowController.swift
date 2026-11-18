import AppKit
import SwiftUI

/// Shows the input-method indicator in a non-activating panel.
///
/// Phase 2 starts with screen and mouse placement. Cursor placement and
/// always-on behavior plug into the same controller in the next phase.
@MainActor
final class IndicatorWindowController {
    static let shared = IndicatorWindowController()

    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    private init() {}

    func show(inputMethodName: String, preferences: IndicatorPreferences) {
        guard preferences.enabled else { return }

        hideTask?.cancel()

        let hostingView = NSHostingView(
            rootView: IndicatorView(
                inputMethodName: inputMethodName,
                style: preferences.style,
                size: preferences.size
            )
        )
        hostingView.layoutSubtreeIfNeeded()

        let measured = hostingView.fittingSize
        let size = CGSize(
            width: max(measured.width, 44),
            height: max(measured.height, 28)
        )
        let mouse = NSEvent.mouseLocation
        let screenFrame = activeScreenFrame(mouse: mouse)
        guard let origin = IndicatorLayout.origin(
            caret: CaretLocator.currentCaretRect(),
            size: size,
            preferences: preferences,
            screenFrame: screenFrame,
            mouse: mouse
        ) else {
            return
        }

        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = hostingView
        panel.setContentSize(size)
        panel.setFrameOrigin(origin)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        hideTask = Task { @MainActor [weak self] in
            let nanoseconds = UInt64(preferences.duration.rawValue * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    func hide() {
        hideTask?.cancel()
        hideTask = nil

        guard let panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        } completionHandler: { [weak panel] in
            panel?.orderOut(nil)
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return panel
    }

    private func activeScreenFrame(mouse: CGPoint) -> CGRect {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        return screen?.visibleFrame ?? .zero
    }
}
