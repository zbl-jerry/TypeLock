import ComposableArchitecture

struct IndicatorClient: Sendable {
    var show: @Sendable (String, String, IndicatorPreferences) -> Void
    var updateAlwaysOn: @Sendable (IndicatorPreferences) -> Void
}

extension IndicatorClient: DependencyKey {
    static let liveValue = IndicatorClient(
        show: { inputMethodId, inputMethodName, preferences in
            Task { @MainActor in
                IndicatorWindowController.shared.show(
                    inputMethodId: inputMethodId,
                    inputMethodName: inputMethodName,
                    preferences: preferences
                )
            }
        },
        updateAlwaysOn: { preferences in
            Task { @MainActor in
                IndicatorWindowController.shared.updateAlwaysOn(preferences: preferences)
            }
        }
    )

    static let testValue = IndicatorClient(show: { _, _, _ in }, updateAlwaysOn: { _ in })
}

extension DependencyValues {
    var indicatorClient: IndicatorClient {
        get { self[IndicatorClient.self] }
        set { self[IndicatorClient.self] = newValue }
    }
}
