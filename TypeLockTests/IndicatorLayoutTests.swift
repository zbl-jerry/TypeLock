import CoreGraphics
@testable import TypeLock
import XCTest

final class IndicatorLayoutTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    private let size = CGSize(width: 120, height: 32)

    func testScreenPositionCentersIndicator() {
        let point = IndicatorLayout.origin(
            caret: nil,
            size: size,
            preferences: IndicatorPreferences(position: .screen),
            screenFrame: screen,
            mouse: .zero
        )

        XCTAssertEqual(point, CGPoint(x: 440, y: 384))
    }

    func testMousePositionClampsToScreenEdges() {
        let topRight = IndicatorLayout.origin(
            caret: nil,
            size: size,
            preferences: IndicatorPreferences(position: .mouse),
            screenFrame: screen,
            mouse: CGPoint(x: 10_000, y: 10_000)
        )
        let bottomLeft = IndicatorLayout.origin(
            caret: nil,
            size: size,
            preferences: IndicatorPreferences(position: .mouse),
            screenFrame: screen,
            mouse: CGPoint(x: -10_000, y: -10_000)
        )

        XCTAssertEqual(topRight, CGPoint(x: 872, y: 760))
        XCTAssertEqual(bottomLeft, CGPoint(x: 8, y: 8))
    }

    func testAlignmentPlacesIndicatorAtScreenPositions() {
        let expected: [(IndicatorAlignment, CGPoint)] = [
            (.topLeft, CGPoint(x: 8, y: 760)),
            (.topCenter, CGPoint(x: 440, y: 760)),
            (.topRight, CGPoint(x: 872, y: 760)),
            (.centerLeft, CGPoint(x: 8, y: 384)),
            (.center, CGPoint(x: 440, y: 384)),
            (.centerRight, CGPoint(x: 872, y: 384)),
            (.bottomLeft, CGPoint(x: 8, y: 8)),
            (.bottomCenter, CGPoint(x: 440, y: 8)),
            (.bottomRight, CGPoint(x: 872, y: 8)),
        ]

        for (alignment, point) in expected {
            XCTAssertEqual(
                IndicatorLayout.screenPoint(
                    frame: screen,
                    size: size,
                    alignment: alignment,
                    spacing: IndicatorSpacing.s.points
                ),
                point,
                "Unexpected position for \(alignment)"
            )
        }
    }

    func testCaretPositions() {
        let caret = CGRect(x: 400, y: 300, width: 2, height: 18)

        XCTAssertEqual(
            IndicatorLayout.pointNearCaret(caret, size: size, position: .above),
            CGPoint(x: 341, y: 326)
        )
        XCTAssertEqual(
            IndicatorLayout.pointNearCaret(caret, size: size, position: .below),
            CGPoint(x: 341, y: 260)
        )
        XCTAssertEqual(
            IndicatorLayout.pointNearCaret(caret, size: size, position: .right),
            CGPoint(x: 410, y: 293)
        )
    }

    func testOnlyAtCursorWithoutCaretDoesNotShow() {
        let point = IndicatorLayout.origin(
            caret: nil,
            size: size,
            preferences: IndicatorPreferences(onlyAtCursor: true),
            screenFrame: screen,
            mouse: CGPoint(x: 500, y: 500)
        )

        XCTAssertNil(point)
    }

    func testPreferCursorFallsBackWhenCaretIsUnavailable() {
        let point = IndicatorLayout.origin(
            caret: nil,
            size: size,
            preferences: IndicatorPreferences(preferCursor: true, position: .screen),
            screenFrame: screen,
            mouse: .zero
        )

        XCTAssertEqual(point, CGPoint(x: 440, y: 384))
    }

    func testCaretOriginIsClamped() {
        let caret = CGRect(x: 995, y: 790, width: 2, height: 18)
        let point = IndicatorLayout.origin(
            caret: caret,
            size: size,
            preferences: IndicatorPreferences(preferCursor: true, cursorPosition: .right),
            screenFrame: screen,
            mouse: .zero
        )

        XCTAssertEqual(point, CGPoint(x: 872, y: 760))
    }
}
