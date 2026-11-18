import ComposableArchitecture
import SwiftUI

struct SwitchStatisticsView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Menu {
            if store.switchStatisticsItems.isEmpty {
                Text(TypeLockStrings.SwitchStatistics.empty)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.switchStatisticsItems) { item in
                    Button {} label: {
                        if item.path != nil {
                            Label {
                                Text(item.name)
                            } icon: {
                                AppInfo(bundleId: item.bundleId, name: item.name, path: item.path).icon
                            }
                        } else {
                            Text(item.name)
                        }
                        Text(TypeLockStrings.SwitchStatistics.appCount(item.count))
                    }
                    .disabled(true)
                }

                Divider()

                Button(role: .destructive) {
                    if MenuConfirmation.confirm(
                        title: TypeLockStrings.SwitchStatistics.ClearConfirmation.title,
                        message: TypeLockStrings.SwitchStatistics.ClearConfirmation.message,
                        confirmButton: TypeLockStrings.SwitchStatistics.ClearConfirmation.confirm
                    ) {
                        store.send(.view(.clearSwitchStatisticsTapped))
                    }
                } label: {
                    Label(TypeLockStrings.SwitchStatistics.clear, systemImage: "trash")
                }
            }
        } label: {
            Label(
                TypeLockStrings.SwitchStatistics.menuTitle(store.totalSuccessfulSwitchCount),
                systemImage: "chart.bar"
            )
        }
    }
}
