import Foundation
@testable import TypeLock
import XCTest

final class SettingsBackupTests: XCTestCase {
    private let timestamp = Date(timeIntervalSince1970: 1_000)

    private func makeRule(
        bundleId: String,
        activation: InputMethodStrategy = .fixed(inputMethodId: "ime.en"),
        launch: AppLaunchStrategy = .fixed(inputMethodId: "ime.en")
    ) -> AppRuleRecord {
        AppRuleRecord(
            bundleId: bundleId,
            lastKnownPath: "/Applications/\(bundleId).app",
            lastKnownName: bundleId,
            strategy: activation,
            launchStrategy: launch,
            createdAt: timestamp,
            updatedAt: timestamp
        )
    }

    private func makeBackup(includeStatistics: Bool = false) -> SettingsBackup {
        SettingsBackup(
            appRulesStore: AppRulesStore(rules: [
                "com.test.editor": makeRule(bundleId: "com.test.editor"),
                "com.test.chat": makeRule(
                    bundleId: "com.test.chat",
                    activation: .followLast(lastInputMethodId: "ime.zh"),
                    launch: .inherit
                ),
            ]),
            fallbackRuleStore: FallbackRuleStore(
                strategy: .fixed(inputMethodId: "ime.abc"),
                launchStrategy: .followLast(lastInputMethodId: "ime.zh")
            ),
            statistics: AppSwitchStatisticsStore(counts: ["com.test.editor": 3]),
            appVersion: "0.11.0",
            buildVersion: "42",
            exportedAt: timestamp,
            includeStatistics: includeStatistics,
            exclusionsStore: ExclusionsStore(
                switchingBundleIds: ["com.test.terminal"],
                indicatorBundleIds: ["com.test.chat"]
            ),
            indicatorPreferences: IndicatorPreferences(
                enabled: true,
                duration: .threeSeconds,
                style: .iconOnly
            ),
            hotkeyPreferences: HotkeyPreferences(bindings: [
                "ime.en": HotkeyBinding(inputMethodId: "ime.en", keyCode: 49, modifiers: 256),
            ])
        )
    }

    func testJSONRoundTripPreservesRulesAndLaunchStrategies() throws {
        let backup = makeBackup(includeStatistics: true)
        let data = try SettingsBackupService.encode(backup)
        let decoded = try SettingsBackupService.decode(data)

        XCTAssertEqual(decoded, backup)
        XCTAssertEqual(decoded.appRules["com.test.chat"]?.launchStrategy, .inherit)
        XCTAssertEqual(decoded.statistics?["com.test.editor"], 3)
        XCTAssertTrue(decoded.exclusions?.isExcludedFromSwitching("com.test.terminal") == true)
        XCTAssertEqual(decoded.indicatorPreferences?.duration, .threeSeconds)
        XCTAssertEqual(decoded.indicatorPreferences?.style, .iconOnly)
        XCTAssertEqual(decoded.hotkeys?.binding(for: "ime.en")?.keyCode, 49)
    }

    func testStatisticsAreOptional() throws {
        let backup = makeBackup(includeStatistics: false)
        let data = try SettingsBackupService.encode(backup)
        let decoded = try SettingsBackupService.decode(data)

        XCTAssertNil(decoded.statistics)
    }

    func testReplacePayloadReplacesEverything() throws {
        let backup = makeBackup(includeStatistics: true)
        let current = SettingsImportPayload(
            appRulesStore: AppRulesStore(rules: ["com.test.current": makeRule(bundleId: "com.test.current")]),
            fallbackRuleStore: FallbackRuleStore(strategy: .none),
            appSwitchStatisticsStore: AppSwitchStatisticsStore(counts: ["com.test.current": 9])
        )

        let payload = try backup.payload(mode: .replace, current: current)

        XCTAssertEqual(Set(payload.appRulesStore.rules.keys), Set(["com.test.editor", "com.test.chat"]))
        XCTAssertEqual(payload.fallbackRuleStore.strategy, .fixed(inputMethodId: "ime.abc"))
        XCTAssertEqual(payload.appSwitchStatisticsStore.counts, ["com.test.editor": 3])
        XCTAssertTrue(payload.exclusionsStore.isExcludedFromSwitching("com.test.terminal"))
        XCTAssertEqual(payload.indicatorPreferences.duration, .threeSeconds)
    }

    func testMergePayloadKeepsCurrentRulesAndImportedWins() throws {
        let backup = makeBackup(includeStatistics: true)
        let current = SettingsImportPayload(
            appRulesStore: AppRulesStore(rules: [
                "com.test.current": makeRule(bundleId: "com.test.current"),
                "com.test.editor": makeRule(bundleId: "com.test.editor", activation: .none),
            ]),
            fallbackRuleStore: FallbackRuleStore(strategy: .none, launchStrategy: .none),
            appSwitchStatisticsStore: AppSwitchStatisticsStore(counts: [
                "com.test.current": 9,
                "com.test.editor": 1,
            ])
        )

        let payload = try backup.payload(mode: .merge, current: current)

        XCTAssertEqual(Set(payload.appRulesStore.rules.keys), Set([
            "com.test.current",
            "com.test.editor",
            "com.test.chat",
        ]))
        XCTAssertEqual(
            payload.appRulesStore.rules["com.test.editor"]?.activationStrategy,
            .fixed(inputMethodId: "ime.en")
        )
        XCTAssertEqual(payload.appSwitchStatisticsStore.counts["com.test.current"], 9)
        XCTAssertEqual(payload.appSwitchStatisticsStore.counts["com.test.editor"], 3)
        XCTAssertTrue(payload.exclusionsStore.isExcludedFromSwitching("com.test.terminal"))
        XCTAssertTrue(payload.exclusionsStore.isExcludedFromIndicator("com.test.chat"))
        XCTAssertEqual(payload.indicatorPreferences.duration, .threeSeconds)
    }

    func testRejectsUnsupportedSchemaVersion() {
        let data = Data(
            #"{"schemaVersion":99,"exportedAt":"1970-01-01T00:00:00Z","appVersion":"1","buildVersion":"1","appRules":{},"fallbackRule":{"v":2,"strategy":{"none":{}},"launchStrategy":{"none":{}}}}"#.utf8
        )

        XCTAssertThrowsError(try SettingsBackupService.decode(data)) { error in
            XCTAssertEqual(error as? SettingsBackupError, .unsupportedSchemaVersion(99))
        }
    }

    func testRejectsMismatchedBundleId() {
        let rule = makeRule(bundleId: "com.test.editor")
        let backup = SettingsBackup(
            appRulesStore: AppRulesStore(rules: ["wrong.key": rule]),
            fallbackRuleStore: FallbackRuleStore(),
            statistics: AppSwitchStatisticsStore(),
            appVersion: "1",
            buildVersion: "1",
            exportedAt: timestamp
        )

        XCTAssertThrowsError(try backup.validate()) { error in
            XCTAssertEqual(
                error as? SettingsBackupError,
                .mismatchedBundleId(key: "wrong.key", recordBundleId: "com.test.editor")
            )
        }
    }

    func testRejectsInvalidFallbackStrategies() {
        let activation = SettingsBackup(
            appRulesStore: AppRulesStore(),
            fallbackRuleStore: FallbackRuleStore(strategy: .followLast(lastInputMethodId: "ime.zh")),
            statistics: AppSwitchStatisticsStore(),
            appVersion: "1",
            buildVersion: "1",
            exportedAt: timestamp
        )
        XCTAssertThrowsError(try activation.validate()) { error in
            XCTAssertEqual(error as? SettingsBackupError, .invalidActivationFallback)
        }

        let launch = SettingsBackup(
            appRulesStore: AppRulesStore(),
            fallbackRuleStore: FallbackRuleStore(launchStrategy: .ignored),
            statistics: AppSwitchStatisticsStore(),
            appVersion: "1",
            buildVersion: "1",
            exportedAt: timestamp
        )
        XCTAssertThrowsError(try launch.validate()) { error in
            XCTAssertEqual(error as? SettingsBackupError, .invalidLaunchFallback)
        }
    }

    func testWriteAndReadRoundTrip() throws {
        let backup = makeBackup(includeStatistics: true)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("typelock-backup-\(UUID().uuidString).json")

        try SettingsBackupService.write(backup, to: url)
        let decoded = try SettingsBackupService.read(from: url)
        try? FileManager.default.removeItem(at: url)

        XCTAssertEqual(decoded, backup)
    }
}
