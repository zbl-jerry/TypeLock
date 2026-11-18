import Foundation

/// Per-feature exclusion lists.
///
/// Switching exclusions skip automatic switching. Indicator exclusions only
/// hide switch feedback; the two lists are intentionally independent.
struct ExclusionsStore: Codable, Hashable, Sendable {
    var v: Int
    var switchingBundleIds: Set<String>
    var indicatorBundleIds: Set<String>

    init(
        v: Int = MigrationVersion.current,
        switchingBundleIds: Set<String> = [],
        indicatorBundleIds: Set<String> = []
    ) {
        self.v = v
        self.switchingBundleIds = switchingBundleIds
        self.indicatorBundleIds = indicatorBundleIds
    }

    func isExcludedFromSwitching(_ bundleId: String) -> Bool {
        switchingBundleIds.contains(bundleId)
    }

    func isExcludedFromIndicator(_ bundleId: String) -> Bool {
        indicatorBundleIds.contains(bundleId)
    }

    mutating func setSwitchingExcluded(_ bundleId: String, _ excluded: Bool) {
        if excluded {
            switchingBundleIds.insert(bundleId)
        } else {
            switchingBundleIds.remove(bundleId)
        }
    }

    mutating func setIndicatorExcluded(_ bundleId: String, _ excluded: Bool) {
        if excluded {
            indicatorBundleIds.insert(bundleId)
        } else {
            indicatorBundleIds.remove(bundleId)
        }
    }

    mutating func migrateIfNeeded() {
        guard v < MigrationVersion.current else { return }
        v = MigrationVersion.current
    }
}
