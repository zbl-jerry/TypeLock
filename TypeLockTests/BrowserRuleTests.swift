import XCTest
@testable import TypeLock

final class BrowserRuleTests: XCTestCase {
    private func rule(
        _ type: BrowserRuleMatchType,
        _ pattern: String,
        enabled: Bool = true
    ) -> BrowserRule {
        BrowserRule(
            matchType: type,
            pattern: pattern,
            inputMethodId: "ime.en",
            enabled: enabled
        )
    }

    func testExactDomainDoesNotMatchSubdomain() throws {
        let url = try XCTUnwrap(URL(string: "https://sub.example.com/path"))
        let exact = rule(.domain, "example.com")
        let suffix = rule(.domainSuffix, "example.com")

        XCTAssertFalse(BrowserRuleMatcher.matches(exact, url: url))
        XCTAssertTrue(BrowserRuleMatcher.matches(suffix, url: url))
        XCTAssertTrue(BrowserRuleMatcher.matches(exact, url: try XCTUnwrap(URL(string: "https://EXAMPLE.com"))))
    }

    func testRegexMatchesFullURL() throws {
        let url = try XCTUnwrap(URL(string: "https://mail.example.com/inbox"))
        let regex = rule(.urlRegex, #"^https://.*\.example\.com/"#)

        XCTAssertTrue(BrowserRuleMatcher.matches(regex, url: url))
    }

    func testInvalidPatternsDoNotMatch() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let invalidRegex = rule(.urlRegex, "[")
        let emptyDomain = rule(.domain, "   ")

        XCTAssertNotNil(BrowserRuleMatcher.validate(invalidRegex))
        XCTAssertNotNil(BrowserRuleMatcher.validate(emptyDomain))
        XCTAssertFalse(BrowserRuleMatcher.matches(invalidRegex, url: url))
        XCTAssertFalse(BrowserRuleMatcher.matches(emptyDomain, url: url))
    }

    func testFirstMatchSkipsDisabledRules() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let disabled = rule(.domain, "example.com", enabled: false)
        let enabled = rule(.domainSuffix, "example.com")

        XCTAssertEqual(
            BrowserRuleMatcher.firstMatch(in: [disabled, enabled], url: url)?.id,
            enabled.id
        )
    }

    func testStoreUpsertsAndRemovesRules() {
        var store = BrowserRulesStore()
        var item = rule(.domain, "example.com")
        store.upsert(item)
        XCTAssertEqual(store.rules.count, 1)

        item.pattern = "example.org"
        store.upsert(item)
        XCTAssertEqual(store.rules.count, 1)
        XCTAssertEqual(store.rules.first?.pattern, "example.org")

        store.remove(id: item.id)
        XCTAssertTrue(store.rules.isEmpty)
    }

    func testLegacyStoreMigrates() {
        var store = BrowserRulesStore(v: 1, rules: [rule(.domain, "example.com")])
        store.migrateIfNeeded()

        XCTAssertEqual(store.v, MigrationVersion.current)
        XCTAssertEqual(store.rules.count, 1)
    }
}
