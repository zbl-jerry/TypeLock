import Foundation

enum UpdateChannelPreferences {
    static let receivesBetaUpdatesKey = "typelock.receivesBetaUpdates"

    static var receivesBetaUpdates: Bool {
        get { UserDefaults.standard.bool(forKey: receivesBetaUpdatesKey) }
        set { UserDefaults.standard.set(newValue, forKey: receivesBetaUpdatesKey) }
    }
}
