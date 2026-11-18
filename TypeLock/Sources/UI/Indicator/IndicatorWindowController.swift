import AppKit
import SwiftUI

/// Shows the input-method indicator in a non-activating panel.
@MainActor
final class IndicatorWindowController {
    static let shared = IndicatorWindowController()

    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?
    private var alwaysOnTask: Task<Void, Never>?
    private var alwaysOnPreferences: IndicatorPreferences?
    private var lastPresentationKey: String?
    private var cachedInputMethodId: String?
    private var cachedInputMethodName: String?

    private init() {}

    func show(
        inputMethodId: String,
        inputMethodName: String,
        preferences: IndicatorPreferences
    ) {
        guard preferences.enabled else { return }

        present(
            inputMethodId: inputMethodId,
            inputMethodName: inputMethodName,
            preferences: preferences,
            caret: CaretLocator.currentCaretRect(),
            autoHide: true
        )
    }

    func updateAlwaysOn(preferences: IndicatorPreferences) {
        alwaysOnPreferences = preferences

        guard preferences.enabled, preferences.alwaysOn else {
            alwaysOnTask?.cancel()
            alwaysOnTask = nil
            return
        }

        guard alwaysOnTask == nil else { return }

        alwaysOnTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self,
                      let current = self.alwaysOnPreferences,
                      current.alwaysOn
                else {
                    return
                }

                if let inputMethod = self.currentInputMethod() {
                    self.present(
                        inputMethodId: inputMethod.id,
                        inputMethodName: inputMethod.name,
                        preferences: current,
                        caret: CaretLocator.currentCaretRect(),
                        autoHide: false
                    )
                } else {
                    self.hide()
                }

                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }

    func hide() {
        hideTask?.cancel()
        hideTask = nil
        lastPresentationKey = nil

        guard let panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        } completionHandler: { [weak panel] in
            panel?.orderOut(nil)
        }
    }

    private func present(
        inputMethodId: String,
        inputMethodName: String,
        preferences: IndicatorPreferences,
        caret: CGRect?,
        autoHide: Bool
    ) {
        if caret == nil, preferences.onlyAtCursor {
            return
        }

        let capsLock = preferences.showCapsLock
            && NSEvent.modifierFlags.contains(.capsLock)
        let appearance = preferences.appearances[inputMethodId]

        let hostingView = NSHostingView(
            rootView: IndicatorView(
                inputMethodName: inputMethodName,
                style: preferences.style,
                size: preferences.size,
                appearance: appearance,
                capsLock: capsLock
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
            caret: caret,
            size: size,
            preferences: preferences,
            screenFrame: screenFrame,
            mouse: mouse
        ) else {
            return
        }

        let key = "\(inputMethodId)|\(preferences.hashValue)|\(capsLock)|\(origin.x)|\(origin.y)"
        if key == lastPresentationKey, panel?.isVisible == true {
            return
        }

        hideTask?.cancel()
        hideTask = nil
        lastPresentationKey = key

        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = hostingView
        panel.setContentSize(size)
        panel.setFrameOrigin(origin)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        guard autoHide else { return }

        hideTask = Task { @MainActor [weak self] in
            let nanoseconds = UInt64(preferences.duration.rawValue * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    private func currentInputMethod() -> (id: String, name: String)? {
        guard let id = try? InputMethodService.getCurrentInputMethodId() else {
            return nil
        }

        if id == cachedInputMethodId, let name = cachedInputMethodName {
            return (id, name)
        }

        let name = (try? InputMethodService.fetchInputMethods())?
            .first(where: { $0.id == id })?
            .name ?? id
        cachedInputMethodId = id
        cachedInputMethodName = name
        return (id, name)
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
