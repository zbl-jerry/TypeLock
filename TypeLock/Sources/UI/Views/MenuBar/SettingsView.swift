import ComposableArchitecture
import SwiftUI

/// 设置视图，包含各种应用设置选项
struct SettingsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Menu {
            InputMethodStrategyMenuContent(
                context: .fallbackRule,
                strategy: store.fallbackStrategy,
                inputMethods: store.inputMethods,
                defaultOptionSubtitle: nil,
                followLastOptionSubtitle: nil,
                unavailableFixedOptionLabel: store.fallbackSelectedLabel
            ) { strategy in
                store.send(.view(.setFallbackStrategy(strategy)))
            }
        } label: {
            Label(
                TypeLockStrings.Settings.Fallback.defaultInputMethod,
                systemImage: "keyboard"
            )
            if let selectedLabel = store.fallbackSelectedLabel {
                Text(selectedLabel)
                    .foregroundStyle(store.fallbackIsSelectedSubtitleSecondary ? .secondary : .primary)
            }
        }

        Menu {
            InputMethodStrategyMenuContent(
                context: .launchFallback,
                strategy: store.fallbackLaunchStrategy,
                inputMethods: store.inputMethods,
                defaultOptionSubtitle: nil,
                followLastOptionSubtitle: nil,
                unavailableFixedOptionLabel: store.fallbackLaunchSelectedLabel
            ) { strategy in
                store.send(.view(.setFallbackLaunchStrategy(strategy)))
            }
        } label: {
            Label("settings.general.launch_input_method", systemImage: "power")
            if let selectedLabel = store.fallbackLaunchSelectedLabel {
                Text(selectedLabel)
                    .foregroundStyle(store.fallbackLaunchIsSelectedSubtitleSecondary ? .secondary : .primary)
            }
        }

        Toggle(
            TypeLockStrings.Settings.General.autoLaunch,
            isOn: Binding(
                get: { store.launchAtLoginEnabled },
                set: { store.send(.view(.setLaunchAtLogin($0))) }
            )
        )
        .toggleStyle(.checkbox)

        if store.launchAtLoginRequiresApproval {
            Text(TypeLockStrings.Settings.General.autoLaunchRequiresApproval)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                LaunchAtLoginService.openSystemSettingsLoginItems()
            } label: {
                Label(TypeLockStrings.Settings.General.openLoginItems, systemImage: "gear")
            }
        }
    }
}
