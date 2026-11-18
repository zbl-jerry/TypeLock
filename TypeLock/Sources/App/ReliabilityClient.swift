import ComposableArchitecture
import Foundation

struct ReliabilityClient: Sendable {
    var settleFocus: @Sendable () -> Void
}

extension ReliabilityClient: DependencyKey {
    static let liveValue = ReliabilityClient {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                InputMethodRepairService.settleFocus()
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    InputMethodRepairService.settleFocus()
                }
            }
        }
    }

    static let testValue = ReliabilityClient {}
}

extension DependencyValues {
    var reliabilityClient: ReliabilityClient {
        get { self[ReliabilityClient.self] }
        set { self[ReliabilityClient.self] = newValue }
    }
}
