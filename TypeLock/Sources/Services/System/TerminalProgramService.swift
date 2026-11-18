import AppKit
import Foundation

/// Reads the foreground program of the frontmost terminal tab.
///
/// Terminal and iTerm2 expose their focused tty through AppleScript. Other
/// terminals currently return nil and fall back to their app rules.
@MainActor
enum TerminalProgramService {
    static let terminalBundleIdentifiers: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "com.github.wez.wezterm",
        "org.alacritty",
    ]

    static func currentProgram() -> String? {
        guard PermissionService.accessibilityStatus == .granted,
              let application = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = application.bundleIdentifier,
              terminalBundleIdentifiers.contains(bundleIdentifier),
              let tty = focusedTTY(bundleIdentifier: bundleIdentifier),
              let processGroupID = foregroundProcessGroup(tty: tty),
              let program = processName(processGroupID: processGroupID)
        else {
            return nil
        }

        return TerminalRule.normalized(program).nilIfEmpty
    }

    private static func focusedTTY(bundleIdentifier: String) -> String? {
        let source: String
        switch bundleIdentifier {
        case "com.apple.Terminal":
            source = #"tell application "Terminal" to get tty of selected tab of front window"#
        case "com.googlecode.iterm2":
            source = #"tell application "iTerm2" to get tty of current session of current window"#
        default:
            return nil
        }

        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        guard error == nil,
              let tty = result.stringValue,
              tty.hasPrefix("/dev/tty"),
              tty.dropFirst("/dev/".count).allSatisfy({ $0.isLetter || $0.isNumber })
        else {
            return nil
        }

        return tty
    }

    private static func foregroundProcessGroup(tty: String) -> Int32? {
        let terminalName = String(tty.dropFirst("/dev/".count))
        guard let output = runPS(arguments: ["-o", "tpgid=", "-t", terminalName]) else {
            return nil
        }

        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { Int32(String($0).trimmingCharacters(in: .whitespaces)) }
            .first { $0 > 0 }
    }

    private static func processName(processGroupID: Int32) -> String? {
        guard let output = runPS(arguments: ["-o", "comm=", "-p", "\(processGroupID)"]) else {
            return nil
        }

        return output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
    }

    private static func runPS(arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
