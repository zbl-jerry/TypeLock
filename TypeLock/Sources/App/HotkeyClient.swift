import ComposableArchitecture

struct HotkeyClient: Sendable {
    var start: @Sendable ([HotkeyBinding], @escaping @Sendable (String) -> Void) -> Void
    var stop: @Sendable () -> Void
}

extension HotkeyClient: DependencyKey {
    static let liveValue = HotkeyClient(
        start: { bindings, onPress in
            Task { @MainActor in
                GlobalHotkeyService.shared.start(bindings: bindings, onPress: onPress)
            }
        },
        stop: {
            Task { @MainActor in
                GlobalHotkeyService.shared.stop()
            }
        }
    )

    static let testValue = HotkeyClient(
        start: { _, _ in },
        stop: {}
    )
}

extension DependencyValues {
    var hotkeyClient: HotkeyClient {
        get { self[HotkeyClient.self] }
        set { self[HotkeyClient.self] = newValue }
    }
}
