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
              let outerTTY = focusedTTY(bundleIdentifier: bundleIdentifier)
        else {
            return nil
        }

        var tty = outerTTY
        if let processGroupID = foregroundProcessGroup(tty: outerTTY),
           let outerProgram = processName(processGroupID: processGroupID),
           TerminalRule.normalized(outerProgram) == "tmux",
           let paneTTY = tmuxPaneTTY(clientTTY: outerTTY)
        {
            tty = paneTTY
        }

        guard let processGroupID = foregroundProcessGroup(tty: tty),
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

    private static func tmuxPaneTTY(clientTTY: String) -> String? {
        let candidates = [
            "/opt/homebrew/bin/tmux",
            "/usr/local/bin/tmux",
            "/usr/bin/tmux",
        ]
        guard let tmux = candidates.first(where: FileManager.default.isExecutableFile(atPath:)),
              let output = runCommand(
                  executable: tmux,
                  arguments: ["list-clients", "-F", "#{client_tty}\t#{pane_tty}"]
              )
        else {
            return nil
        }

        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: "\t", maxSplits: 1).map(String.init)
            guard fields.count == 2 else { continue }
            if fields[0] == clientTTY, fields[1].hasPrefix("/dev/") {
                return fields[1]
            }
        }

        return nil
    }

    private static func runPS(arguments: [String]) -> String? {
        runCommand(executable: "/bin/ps", arguments: arguments)
    }

    private static func runCommand(executable: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
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
