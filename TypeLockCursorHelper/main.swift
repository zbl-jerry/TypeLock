import AppKit
import ApplicationServices
import Foundation

guard CommandLine.arguments.contains("--caret") else {
    exit(2)
}

guard AXIsProcessTrusted() else {
    exit(3)
}

let systemWide = AXUIElementCreateSystemWide()
var focusedValue: CFTypeRef?
guard AXUIElementCopyAttributeValue(
    systemWide,
    kAXFocusedUIElementAttribute as CFString,
    &focusedValue
) == .success,
    let focusedValue
else {
    exit(4)
}

let focused = focusedValue as! AXUIElement
var positionValue: CFTypeRef?
var sizeValue: CFTypeRef?
guard AXUIElementCopyAttributeValue(
    focused,
    kAXPositionAttribute as CFString,
    &positionValue
) == .success,
    let positionValue
else {
    exit(5)
}
guard AXUIElementCopyAttributeValue(
    focused,
    kAXSizeAttribute as CFString,
    &sizeValue
) == .success,
    let sizeValue
else {
    exit(6)
}

var origin = CGPoint.zero
var size = CGSize.zero
guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin),
      AXValueGetValue(sizeValue as! AXValue, .cgSize, &size),
      size.width > 0,
      size.height > 0
else {
    exit(7)
}

let primaryMaxY = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.maxY
    ?? NSScreen.screens.first?.frame.maxY
    ?? origin.y + size.height
let convertedY = primaryMaxY - origin.y - size.height

let payload: [String: Double] = [
    "x": origin.x,
    "y": convertedY,
    "width": size.width,
    "height": size.height,
]
let data = try JSONSerialization.data(withJSONObject: payload)
FileHandle.standardOutput.write(data)
exit(0)
