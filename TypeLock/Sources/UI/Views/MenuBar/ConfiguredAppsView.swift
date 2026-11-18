import ComposableArchitecture
import SwiftUI

/// 已配置的应用列表视图
struct ConfiguredAppsView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        if !store.configuredApps.isEmpty {
            Menu {
                if store.hasMissingInputMethodRules {
                    Button(role: .destructive) {
                        if MenuConfirmation.confirm(
                            title: TypeLockStrings.InputMethod.ClearMissingConfirmation.title,
                            message: TypeLockStrings.InputMethod.ClearMissingConfirmation.message,
                            confirmButton: TypeLockStrings.InputMethod.ClearMissingConfirmation.confirm
                        ) {
                            store.send(.view(.removeMissingInputMethodRulesTapped))
                        }
                    } label: {
                        Label(
                            TypeLockStrings.InputMethod.clearMissingConfiguration,
                            systemImage: "trash"
                        )
                    }

                    Divider()
                }

                ForEach(store.configuredApps) { item in
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
                    TypeLockStrings.Apps.Section.configuredCount(store.configuredApps.count),
                    systemImage: "list.bullet.rectangle"
                )
            }
        }
    }
}
