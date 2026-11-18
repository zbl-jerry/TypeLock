import Foundation
@testable import TypeLock
import XCTest

final class AppStorageCompatibilityTests: XCTestCase {
    func testAppRulesStoreEncodingIncludesVersion() throws {
        let store = AppRulesStore(
            v: MigrationVersion.current,
            rules: [
                "com.test.notes": AppRuleRecord(
                    bundleId: "com.test.notes",
                    lastKnownPath: "/Applications/Notes.app",
                    lastKnownName: "Notes",
                    strategy: .fixed(inputMethodId: "ime.zh"),
                    createdAt: Date(timeIntervalSince1970: 10),
                    updatedAt: Date(timeIntervalSince1970: 20)
                ),
            ]
        )

        let data = try JSONEncoder().encode(store)
        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(payload["v"] as? Int, MigrationVersion.current)
        XCTAssertEqual(try JSONDecoder().decode(AppRulesStore.self, from: data), store)
    }

    func testAppRulesStoreRoundTripsIgnoredStrategy() throws {
        let store = AppRulesStore(
            rules: [
                "com.test.passwords": AppRuleRecord(
                    bundleId: "com.test.passwords",
                    lastKnownPath: "/Applications/Passwords.app",
                    lastKnownName: "Passwords",
                    strategy: .ignored,
                    strategyBeforeIgnoring: .followLast(lastInputMethodId: "ime.zh"),
                    createdAt: Date(timeIntervalSince1970: 10),
                    updatedAt: Date(timeIntervalSince1970: 20)
                ),
            ]
        )

        let data = try JSONEncoder().encode(store)

        XCTAssertEqual(try JSONDecoder().decode(AppRulesStore.self, from: data), store)
    }

    func testLegacyIgnoredRuleWithoutPreviousStrategyDecodesWithNil() throws {
        let data = Data(
            #"{"bundleId":"com.test.passwords","lastKnownName":"Passwords","strategy":{"ignored":{}},"createdAt":0,"updatedAt":0}"#.utf8
        )

        let rule = try JSONDecoder().decode(AppRuleRecord.self, from: data)

        XCTAssertEqual(rule.strategy, .ignored)
        XCTAssertEqual(rule.activationStrategy, .ignored)
        XCTAssertNil(rule.strategyBeforeIgnoring)
        XCTAssertEqual(rule.launchStrategy, .inherit)
    }

    func testLaunchStrategyRoundTripsAndDoesNotChangeActivationStrategy() throws {
        let rule = AppRuleRecord(
            bundleId: "com.test.editor",
            lastKnownPath: "/Applications/Editor.app",
            lastKnownName: "Editor",
            strategy: .fixed(inputMethodId: "ime.zh"),
            launchStrategy: .fixed(inputMethodId: "ime.abc"),
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20)
        )

        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(AppRuleRecord.self, from: data)

        XCTAssertEqual(decoded, rule)
        XCTAssertEqual(decoded.activationStrategy, .fixed(inputMethodId: "ime.zh"))
        XCTAssertEqual(decoded.launchStrategy, .fixed(inputMethodId: "ime.abc"))
    }

    func testLegacyRulesStoreMigratesToCurrentVersion() throws {
        let legacy = Data(
            #"{"v":1,"rules":{"com.test.notes":{"bundleId":"com.test.notes","lastKnownName":"Notes","strategy":{"none":{}},"createdAt":0,"updatedAt":0}}}"#.utf8
        )
        var store = try JSONDecoder().decode(AppRulesStore.self, from: legacy)

        XCTAssertEqual(store.v, 1)
        XCTAssertEqual(store.rules["com.test.notes"]?.launchStrategy, .inherit)

        store.migrateIfNeeded()

        XCTAssertEqual(store.v, MigrationVersion.current)
        XCTAssertEqual(store.rules["com.test.notes"]?.launchStrategy, .inherit)
    }

    func testFallbackRuleStoreMigratesToCurrentVersion() {
        var store = FallbackRuleStore(v: 1, strategy: .fixed(inputMethodId: "ime.abc"))

        store.migrateIfNeeded()

        XCTAssertEqual(store.v, MigrationVersion.current)
        XCTAssertEqual(store.strategy, .fixed(inputMethodId: "ime.abc"))
    }

    func testExistingInputMethodStrategiesStillDecode() throws {
        let decoder = JSONDecoder()

        XCTAssertEqual(
            try decoder.decode(InputMethodStrategy.self, from: Data(#"{"none":{}}"#.utf8)),
            .none
        )
        XCTAssertEqual(
            try decoder.decode(InputMethodStrategy.self, from: Data(#"{"fixed":{"inputMethodId":"ime.zh"}}"#.utf8)),
            .fixed(inputMethodId: "ime.zh")
        )
        XCTAssertEqual(
            try decoder.decode(InputMethodStrategy.self, from: Data(#"{"followLast":{"lastInputMethodId":"ime.jp"}}"#.utf8)),
            .followLast(lastInputMethodId: "ime.jp")
        )
    }

    func testFallbackRuleStoreDefaultsAndEncodingIncludeVersion() throws {
        let defaultStore = FallbackRuleStore()
        XCTAssertEqual(defaultStore.v, MigrationVersion.current)
        XCTAssertEqual(defaultStore.strategy, .none)
        XCTAssertEqual(defaultStore.launchStrategy, .none)

        let store = FallbackRuleStore(
            strategy: .fixed(inputMethodId: "ime.abc"),
            launchStrategy: .followLast(lastInputMethodId: "ime.zh")
        )
        let data = try JSONEncoder().encode(store)
        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(payload["v"] as? Int, MigrationVersion.current)
        XCTAssertEqual(try JSONDecoder().decode(FallbackRuleStore.self, from: data), store)
    }

    func testLegacyFallbackRuleStoreDecodesWithoutLaunchStrategy() throws {
        let data = Data(
            #"{"v":1,"strategy":{"fixed":{"inputMethodId":"ime.abc"}}}"#.utf8
        )

        let store = try JSONDecoder().decode(FallbackRuleStore.self, from: data)

        XCTAssertEqual(store.v, 1)
        XCTAssertEqual(store.strategy, .fixed(inputMethodId: "ime.abc"))
        XCTAssertEqual(store.launchStrategy, .none)
    }

    func testAppSwitchStatisticsStoreDefaultsAndEncoding() throws {
        let defaultStore = AppSwitchStatisticsStore()
        XCTAssertTrue(defaultStore.counts.isEmpty)

        let store = AppSwitchStatisticsStore(counts: [
            "com.test.notes": 2,
            "com.test.browser": 5,
        ])
        let data = try JSONEncoder().encode(store)

        XCTAssertEqual(try JSONDecoder().decode(AppSwitchStatisticsStore.self, from: data), store)
    }

    func testAppRulesStoreURLUsesBundleIdentifierDirectory() {
        let applicationSupportDirectory = URL(fileURLWithPath: "/tmp/Application Support", isDirectory: true)
        let url = URL.appRulesStoreFileURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: "com.test.TypeLock"
        )

        XCTAssertEqual(
            url.path,
            applicationSupportDirectory
                .appending(path: "com.test.TypeLock", directoryHint: .isDirectory)
                .appending(path: AppStorageConfiguration.appRulesFilename)
                .path
        )
    }

    func testFallbackRuleStoreURLUsesFallbackRuleFilename() {
        let applicationSupportDirectory = URL(fileURLWithPath: "/tmp/Application Support", isDirectory: true)
        let url = URL.fallbackRuleStoreFileURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: "com.test.TypeLock"
        )

        XCTAssertEqual(AppStorageConfiguration.fallbackRuleFilename, "fallback-rule.json")
        XCTAssertEqual(
            url.path,
            applicationSupportDirectory
                .appending(path: "com.test.TypeLock", directoryHint: .isDirectory)
                .appending(path: AppStorageConfiguration.fallbackRuleFilename)
                .path
        )
        XCTAssertNotEqual(url, URL.appRulesStoreFileURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: "com.test.TypeLock"
        ))
    }

    func testAppSwitchStatisticsStoreURLUsesStatisticsFilename() {
        let applicationSupportDirectory = URL(fileURLWithPath: "/tmp/Application Support", isDirectory: true)
        let url = URL.appSwitchStatisticsStoreFileURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: "com.test.TypeLock"
        )

        XCTAssertEqual(AppStorageConfiguration.appSwitchStatisticsFilename, "app-switch-statistics.json")
        XCTAssertEqual(
            url.path,
            applicationSupportDirectory
                .appending(path: "com.test.TypeLock", directoryHint: .isDirectory)
                .appending(path: AppStorageConfiguration.appSwitchStatisticsFilename)
                .path
        )
        XCTAssertNotEqual(url, URL.appRulesStoreFileURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: "com.test.TypeLock"
        ))
        XCTAssertNotEqual(url, URL.fallbackRuleStoreFileURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: "com.test.TypeLock"
        ))
    }
}
