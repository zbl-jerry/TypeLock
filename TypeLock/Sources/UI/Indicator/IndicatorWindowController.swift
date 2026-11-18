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
        guard preferences.enabled, !preferences.onlyAtCursor else { return }

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

        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = hostingView
        panel.setContentSize(size)
        panel.setFrameOrigin(origin(for: size, preferences: preferences))
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

    private func origin(for size: CGSize, preferences: IndicatorPreferences) -> CGPoint {
        switch preferences.position {
        case .screen:
            let frame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame ?? .zero
            return CGPoint(
                x: frame.midX - size.width / 2,
                y: frame.midY - size.height / 2
            )
        case .mouse:
            let mouse = NSEvent.mouseLocation
            let frame = NSScreen.screens.first(where: { $0.frame.contains(mouse) })?.visibleFrame
                ?? NSScreen.main?.visibleFrame
                ?? .zero
            let proposed = CGPoint(x: mouse.x + 12, y: mouse.y + 12)
            return CGPoint(
                x: min(max(proposed.x, frame.minX + 8), frame.maxX - size.width - 8),
                y: min(max(proposed.y, frame.minY + 8), frame.maxY - size.height - 8)
            )
        }
    }
}
