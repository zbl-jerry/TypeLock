import ComposableArchitecture
import Foundation

struct TerminalProgramClient: Sendable {
    var currentProgram: @Sendable () -> String?
}

extension TerminalProgramClient: DependencyKey {
    static let liveValue = TerminalProgramClient {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                TerminalProgramService.currentProgram()
            }
        }

        return DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                TerminalProgramService.currentProgram()
            }
        }
    }

    static let testValue = TerminalProgramClient { nil }
}

extension DependencyValues {
    var terminalProgramClient: TerminalProgramClient {
        get { self[TerminalProgramClient.self] }
        set { self[TerminalProgramClient.self] = newValue }
    }
}
