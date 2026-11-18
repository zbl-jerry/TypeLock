import XCTest
@testable import TypeLock

final class SwitchResolverTests: XCTestCase {
    func testAppStrategyWinsOverFallback() {
        let resolution = SwitchResolver.resolveActivation(
            appStrategy: .fixed(inputMethodId: "ime.app"),
            fallbackStrategy: .fixed(inputMethodId: "ime.fallback")
        )

        XCTAssertEqual(resolution.strategy, .fixed(inputMethodId: "ime.app"))
        XCTAssertEqual(resolution.source, .app)
    }

    func testUnconfiguredAppUsesFixedFallback() {
        let resolution = SwitchResolver.resolveActivation(
            appStrategy: .none,
            fallbackStrategy: .fixed(inputMethodId: "ime.fallback")
        )

        XCTAssertEqual(resolution.strategy, .fixed(inputMethodId: "ime.fallback"))
        XCTAssertEqual(resolution.source, .fallback)
    }

    func testFollowLastAppStrategyIsPreserved() {
        let resolution = SwitchResolver.resolveActivation(
            appStrategy: .followLast(lastInputMethodId: "ime.zh"),
            fallbackStrategy: .none
        )

        XCTAssertEqual(resolution.strategy, .followLast(lastInputMethodId: "ime.zh"))
        XCTAssertEqual(resolution.source, .app)
    }

    func testIgnoredAppStrategyIsPreserved() {
        let resolution = SwitchResolver.resolveActivation(
            appStrategy: .ignored,
            fallbackStrategy: .fixed(inputMethodId: "ime.fallback")
        )

        XCTAssertEqual(resolution.strategy, .ignored)
        XCTAssertEqual(resolution.source, .app)
    }

    func testFallbackNormalizesFollowLastAndIgnoredToNoSwitch() {
        XCTAssertEqual(SwitchResolver.normalizedFallback(.followLast(lastInputMethodId: "ime.zh")), .none)
        XCTAssertEqual(SwitchResolver.normalizedFallback(.ignored), .none)
        XCTAssertEqual(SwitchResolver.normalizedFallback(.none), .none)
        XCTAssertEqual(
            SwitchResolver.normalizedFallback(.fixed(inputMethodId: "ime.abc")),
            .fixed(inputMethodId: "ime.abc")
        )
    }

    func testUnconfiguredAppWithUnsupportedFallbackDoesNotSwitch() {
        let resolution = SwitchResolver.resolveActivation(
            appStrategy: .none,
            fallbackStrategy: .followLast(lastInputMethodId: "ime.zh")
        )

        XCTAssertEqual(resolution.strategy, .none)
        XCTAssertEqual(resolution.source, .fallback)
    }
}
