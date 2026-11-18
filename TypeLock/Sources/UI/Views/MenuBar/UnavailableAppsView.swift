import ComposableArchitecture
import SwiftUI

struct UnavailableAppsView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        if !store.unavailableApps.isEmpty {
            Menu {
                Button(role: .destructive) {
                    if MenuConfirmation.confirm(
                        title: TypeLockStrings.Apps.ClearUnavailableConfirmation.title,
                        message: TypeLockStrings.Apps.ClearUnavailableConfirmation.message,
                        confirmButton: TypeLockStrings.Apps.ClearUnavailableConfirmation.confirm
                    ) {
                        store.send(.view(.removeUnavailableRulesTapped))
                    }
                } label: {
                    Label(TypeLockStrings.Apps.clearUnavailable, systemImage: "trash")
                }

                Divider()

                ForEach(store.unavailableApps) { item in
                    AppRowView(
                        item: item,
                        inputMethods: store.inputMethods,
                        onIgnore: {
                            store.send(.view(.ignoreAppTapped(item.appInfo)))
                        }
                    ) { strategy in
                        store.send(.view(.setStrategy(bundleId: item.bundleId, strategy: strategy)))
                    }
                }
            } label: {
                Label(
                    TypeLockStrings.Apps.Section.unavailableCount(store.unavailableApps.count),
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
    }
}
