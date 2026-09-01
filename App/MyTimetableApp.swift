import SwiftUI

@main
struct MyTimetableApp: App {
    @StateObject private var store = AppStore()

    init() {
        TaskNotificationManager.shared.configureForegroundPresentation()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    await TaskNotificationManager.shared.refresh(
                        tasks: store.snapshot.tasks
                    )
                }
        }
    }
}
