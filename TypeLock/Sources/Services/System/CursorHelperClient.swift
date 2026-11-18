import AppKit
import Darwin
import Foundation

/// Best-effort bridge to the optional Cursor Helper executable.
enum CursorHelperClient {
    private static let helperName = "TypeLockCursorHelper"

    static func caretRect() -> CGRect? {
        guard let helperURL else { return nil }

        let process = Process()
        process.executableURL = helperURL
        process.arguments = ["--caret"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return nil
        }

        let deadline = Date().addingTimeInterval(0.25)
        while process.isRunning && Date() < deadline {
            usleep(10_000)
        }
        if process.isRunning {
            process.terminate()
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Double],
            let x = object["x"],
            let y = object["y"],
            let width = object["width"],
            let height = object["height"]
        else {
            return nil
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static var helperURL: URL? {
        if let auxiliary = Bundle.main.path(forAuxiliaryExecutable: helperName) {
            return URL(fileURLWithPath: auxiliary)
        }

        let bundled = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Helpers")
            .appendingPathComponent(helperName)
        if FileManager.default.isExecutableFile(atPath: bundled.path) {
            return bundled
        }

        return nil
    }
}
