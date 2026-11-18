import Foundation

enum MigrationVersion {
    /// Version 2 adds per-app launch strategies while keeping the legacy
    /// activation `strategy` key readable.
    static let current = 2
}
