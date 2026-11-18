import Foundation

/// The strategy applied the first time an app becomes frontmost after launching.
///
/// `inherit` means the app uses the global launch strategy. `none` explicitly
/// performs no switch for this app.
enum AppLaunchStrategy: Codable, Hashable, Sendable {
    case inherit
    case none
    case fixed(inputMethodId: String)
    case followLast(lastInputMethodId: String?)
}

extension AppLaunchStrategy {
    var inputMethodStrategy: InputMethodStrategy? {
        switch self {
        case .inherit:
            return nil
        case .none:
            return .none
        case let .fixed(inputMethodId):
            return .fixed(inputMethodId: inputMethodId)
        case let .followLast(lastInputMethodId):
            return .followLast(lastInputMethodId: lastInputMethodId)
        }
    }
}
