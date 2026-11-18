import Foundation

enum AppStorageConfiguration {
    static let appRulesFilename = "app-rules.json"
    static let appSwitchStatisticsFilename = "app-switch-statistics.json"
    static let fallbackRuleFilename = "fallback-rule.json"
    static let exclusionsFilename = "exclusions.json"
    static let indicatorPreferencesFilename = "indicator.json"
    static let hotkeyPreferencesFilename = "hotkeys.json"
    static let browserRulesFilename = "browser-rules.json"
    static let terminalRulesFilename = "terminal-rules.json"
    static let reliabilityPreferencesFilename = "reliability.json"

    private final class BundleLocator {}

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier
            ?? Bundle(for: BundleLocator.self).bundleIdentifier
            ?? "TypeLock"
    }
}

extension URL {
    static func appStorageDirectoryURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        applicationSupportDirectory.appending(path: bundleIdentifier, directoryHint: .isDirectory)
    }

    static func appRulesStoreFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.appRulesFilename)
    }

    static func fallbackRuleStoreFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.fallbackRuleFilename)
    }

    static func appSwitchStatisticsStoreFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.appSwitchStatisticsFilename)
    }

    static func exclusionsStoreFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.exclusionsFilename)
    }

    static func indicatorPreferencesFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.indicatorPreferencesFilename)
    }

    static let appRulesStoreURL = appRulesStoreFileURL()
    static let appSwitchStatisticsStoreURL = appSwitchStatisticsStoreFileURL()
    static let fallbackRuleStoreURL = fallbackRuleStoreFileURL()
    static func hotkeyPreferencesFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.hotkeyPreferencesFilename)
    }

    static func browserRulesFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.browserRulesFilename)
    }

    static let exclusionsStoreURL = exclusionsStoreFileURL()
    static let indicatorPreferencesURL = indicatorPreferencesFileURL()
    static let hotkeyPreferencesURL = hotkeyPreferencesFileURL()
    static func terminalRulesFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.terminalRulesFilename)
    }

    static let browserRulesURL = browserRulesFileURL()
    static func reliabilityPreferencesFileURL(
        applicationSupportDirectory: URL = .applicationSupportDirectory,
        bundleIdentifier: String = AppStorageConfiguration.bundleIdentifier
    ) -> URL {
        appStorageDirectoryURL(
            applicationSupportDirectory: applicationSupportDirectory,
            bundleIdentifier: bundleIdentifier
        )
        .appending(path: AppStorageConfiguration.reliabilityPreferencesFilename)
    }

    static let terminalRulesURL = terminalRulesFileURL()
    static let reliabilityPreferencesURL = reliabilityPreferencesFileURL()
}
