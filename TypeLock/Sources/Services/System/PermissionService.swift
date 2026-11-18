import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum PermissionStatus: Equatable, Sendable {
    case granted
    case denied
}

/// Permission checks used by the settings and terminal flows.
///
/// Accessibility and Input Monitoring are checked lazily; Apple Events cannot
/// be queried ahead of time and are handled by the terminal feature.
enum PermissionService {
    static var accessibilityStatus: PermissionStatus {
        AXIsProcessTrusted() ? .granted : .denied
    }

    @MainActor
    static func requestAccessibility() -> PermissionStatus {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true,
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options) ? .granted : .denied
    }

    static var inputMonitoringStatus: PermissionStatus {
        CGPreflightListenEventAccess() ? .granted : .denied
    }

    @MainActor
    static func requestInputMonitoring() -> PermissionStatus {
        CGRequestListenEventAccess() ? .granted : .denied
    }

    @MainActor
    static func openAccessibilitySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    @MainActor
    static func openInputMonitoringSettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    @MainActor
    static func openLoginItemsSettings() {
        LaunchAtLoginService.openSystemSettingsLoginItems()
    }

    @MainActor
    private static func openSystemSettings(_ value: String) {
        guard let url = URL(string: value) else { return }
        NSWorkspace.shared.open(url)
    }
}
