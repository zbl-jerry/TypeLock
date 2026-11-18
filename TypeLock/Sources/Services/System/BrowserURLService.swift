import AppKit
import ApplicationServices
import Foundation

/// Reads the current page URL of a supported browser through Accessibility.
enum BrowserURLService {
    static let supportedBundleIdentifiers: Set<String> = [
        "com.apple.Safari",
        "com.apple.SafariTechnologyPreview",
        "com.google.Chrome",
        "org.chromium.Chromium",
        "company.thebrowser.Browser",
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "com.brave.Browser.beta",
        "com.brave.Browser.nightly",
        "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera",
        "org.mozilla.firefox",
        "org.mozilla.firefoxdeveloperedition",
        "org.mozilla.nightly",
        "app.zen-browser.zen",
        "company.thebrowser.dia",
        "net.imput.helium",
        "ai.perplexity.comet",
        "at.studio.AsideBrowser",
        "com.naver.Whale",
    ]

    @MainActor
    static func currentURL() -> URL? {
        guard PermissionService.accessibilityStatus == .granted,
              let application = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = application.bundleIdentifier,
              supportedBundleIdentifiers.contains(bundleIdentifier)
        else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)

        if let url = documentURL(from: appElement) {
            return url
        }

        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowValue
        ) == .success,
            let windowValue
        else {
            return nil
        }

        return documentURL(from: windowValue as! AXUIElement)
    }

    private static func documentURL(from element: AXUIElement, depth: Int = 0) -> URL? {
        guard depth < 4 else { return nil }

        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXDocumentAttribute as CFString,
            &value
        ) == .success,
            let string = value as? String,
            let url = URL(string: string),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        {
            return url
        }

        var focusedValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        ) == .success,
            let focusedValue
        {
            return documentURL(from: focusedValue as! AXUIElement, depth: depth + 1)
        }

        return nil
    }
}
