import AppKit
import Carbon
import SwiftUI

@MainActor
enum InputMethodIconCache {
    private static var images: [String: NSImage] = [:]
    private static var missing: Set<String> = []

    static func image(for inputMethodId: String) -> NSImage? {
        if let image = images[inputMethodId] {
            return image
        }
        if missing.contains(inputMethodId) {
            return nil
        }

        guard let inputSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue()
            as? [TISInputSource]
        else {
            missing.insert(inputMethodId)
            return nil
        }

        for source in inputSources {
            guard let idPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
                continue
            }
            let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String
            guard id == inputMethodId else { continue }

            guard let urlPointer = TISGetInputSourceProperty(source, kTISPropertyIconImageURL) else {
                break
            }
            let url = Unmanaged<CFURL>.fromOpaque(urlPointer).takeUnretainedValue() as URL
            if let image = NSImage(contentsOf: url) {
                images[inputMethodId] = image
                return image
            }
            break
        }

        missing.insert(inputMethodId)
        return nil
    }
}

@MainActor
struct InputMethodIconView: View {
    let inputMethodId: String

    var body: some View {
        if let image = InputMethodIconCache.image(for: inputMethodId) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: "keyboard")
                .frame(width: 16, height: 16)
        }
    }
}
