import Carbon
import Foundation

@MainActor
final class GlobalHotkeyService {
    static let shared = GlobalHotkeyService()

    private static let signature = OSType(0x54594C4B) // "TYLK"

    private var handlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var idToInputMethod: [UInt32: String] = [:]
    private var callback: ((String) -> Void)?

    private init() {}

    func start(bindings: [HotkeyBinding], onPress: @escaping (String) -> Void) {
        stop()
        guard !bindings.isEmpty else { return }

        callback = onPress
        installHandlerIfNeeded()

        for (index, binding) in bindings.enumerated() {
            let id = UInt32(index + 1)
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.keyCode,
                binding.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            guard status == noErr, let hotKeyRef else { continue }

            hotKeyRefs.append(hotKeyRef)
            idToInputMethod[id] = binding.inputMethodId
        }
    }

    func stop() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
        idToInputMethod.removeAll()
        callback = nil

        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    fileprivate func handle(id: UInt32) {
        guard let inputMethodId = idToInputMethod[id] else { return }
        callback?(inputMethodId)
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return status }

                let service = Unmanaged<GlobalHotkeyService>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                Task { @MainActor in
                    service.handle(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
    }
}
