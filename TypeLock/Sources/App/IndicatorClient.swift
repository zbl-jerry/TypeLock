import ComposableArchitecture

struct IndicatorClient: Sendable {
    var show: @Sendable (String, IndicatorPreferences) -> Void
}

extension IndicatorClient: DependencyKey {
    static let liveValue = IndicatorClient { inputMethodName, preferences in
        Task { @MainActor in
            IndicatorWindowController.shared.show(
                inputMethodName: inputMethodName,
                preferences: preferences
            )
        }
    }

    static let testValue = IndicatorClient { _, _ in }
}

extension DependencyValues {
    var indicatorClient: IndicatorClient {
        get { self[IndicatorClient.self] }
        set { self[IndicatorClient.self] = newValue }
    }
}
