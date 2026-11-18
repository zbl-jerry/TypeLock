import Foundation

enum AppStorageConfiguration {
    static let appRulesFilename = "app-rules.json"
    static let appSwitchStatisticsFilename = "app-switch-statistics.json"
    static let fallbackRuleFilename = "fallback-rule.json"
    static let exclusionsFilename = "exclusions.json"

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

    static let appRulesStoreURL = appRulesStoreFileURL()
    static let appSwitchStatisticsStoreURL = appSwitchStatisticsStoreFileURL()
    static let fallbackRuleStoreURL = fallbackRuleStoreFileURL()
    static let exclusionsStoreURL = exclusionsStoreFileURL()
}
