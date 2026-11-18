import XCTest
@testable import TypeLock

final class TerminalRuleTests: XCTestCase {
    func testProgramMatchingNormalizesPathAndCase() {
        let rule = TerminalRule(program: "/usr/local/bin/Claude", inputMethodId: "ime.en")

        XCTAssertTrue(rule.matches(program: "claude"))
        XCTAssertTrue(rule.matches(program: "CLAUDE"))
        XCTAssertFalse(rule.matches(program: "claude-code"))
    }

    func testDisabledRulesDoNotMatch() {
        var store = TerminalRulesStore()
        var rule = TerminalRule(program: "nvim", inputMethodId: "ime.en")
        store.upsert(rule)
        XCTAssertNotNil(store.firstMatch(program: "nvim"))

        rule.enabled = false
        store.upsert(rule)
        XCTAssertNil(store.firstMatch(program: "nvim"))
    }

    func testStoreUpsertsAndRemovesRules() {
        var store = TerminalRulesStore()
        var rule = TerminalRule(program: "nvim", inputMethodId: "ime.en")
        store.upsert(rule)
        XCTAssertEqual(store.rules.count, 1)

        rule.program = "vim"
        store.upsert(rule)
        XCTAssertEqual(store.rules.count, 1)
        XCTAssertEqual(store.rules.first?.program, "vim")

        store.remove(id: rule.id)
        XCTAssertTrue(store.rules.isEmpty)
    }

    func testLegacyStoreMigrates() {
        var store = TerminalRulesStore(
            v: 1,
            rules: [TerminalRule(program: "nvim", inputMethodId: "ime.en")]
        )
        store.migrateIfNeeded()

        XCTAssertEqual(store.v, MigrationVersion.current)
        XCTAssertEqual(store.rules.count, 1)
    }
}
