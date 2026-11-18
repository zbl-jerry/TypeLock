import ComposableArchitecture
import Foundation

struct BrowserURLClient: Sendable {
    var currentURL: @Sendable () -> URL?
}

extension BrowserURLClient: DependencyKey {
    static let liveValue = BrowserURLClient {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                BrowserURLService.currentURL()
            }
        }

        return DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                BrowserURLService.currentURL()
            }
        }
    }

    static let testValue = BrowserURLClient { nil }
}

extension DependencyValues {
    var browserURLClient: BrowserURLClient {
        get { self[BrowserURLClient.self] }
        set { self[BrowserURLClient.self] = newValue }
    }
}
