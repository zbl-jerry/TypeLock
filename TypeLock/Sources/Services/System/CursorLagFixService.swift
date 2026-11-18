import Foundation

/// Disables macOS 14's experimental text cursor, which can freeze
/// CursorUIViewService and cause typing or cursor lag.
enum CursorLagFixService {
    static func setEnabled(_ enabled: Bool) throws {
        let value = enabled ? "NO" : "YES"
        let command = """
        defaults write /Library/Preferences/FeatureFlags/Domain/UIKit.plist \
        redesigned_text_cursor -dict-add Enabled -\(value); \
        killall CursorUIViewService 2>/dev/null; true
        """

        let script = "do shell script \"\(command.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? ""
            throw CursorLagFixError.failed(message)
        }
    }
}

enum CursorLagFixError: LocalizedError {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case let .failed(message):
            return message
        }
    }
}
