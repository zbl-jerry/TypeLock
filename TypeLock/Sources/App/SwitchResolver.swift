import Foundation

/// Pure rules for selecting the strategy for a switch scene.
///
/// The resolver owns precedence and fallback normalization so every switch
/// path (activation, launch, shortcuts, browser rules, terminal rules) can use
/// the same rules as more scenes are added.
enum SwitchResolver {
    enum Source: Equatable, Sendable {
        case app
        case fallback
    }

    struct Resolution: Equatable, Sendable {
        let strategy: InputMethodStrategy
        let source: Source
    }

    /// Resolves the strategy applied when an app returns to the foreground.
    static func resolveActivation(
        appStrategy: InputMethodStrategy,
        fallbackStrategy: InputMethodStrategy
    ) -> Resolution {
        guard appStrategy == .none else {
            return Resolution(strategy: appStrategy, source: .app)
        }

        return Resolution(
            strategy: normalizedFallback(fallbackStrategy),
            source: .fallback
        )
    }

    /// The global fallback only supports no-switch and fixed input methods.
    /// Remembering or ignoring an unconfigured app has no meaning at this level.
    static func normalizedFallback(_ strategy: InputMethodStrategy) -> InputMethodStrategy {
        switch strategy {
        case .followLast, .ignored:
            return .none
        case .none, .fixed:
            return strategy
        }
    }
}
