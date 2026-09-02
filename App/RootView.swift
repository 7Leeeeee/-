import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingTaskEditor = false

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(showingTaskEditor: $showingTaskEditor)
            }
            .tabItem { Label("今天", systemImage: "sun.max.fill") }

            NavigationStack {
                WeekScheduleView(showingTaskEditor: $showingTaskEditor)
            }
            .tabItem { Label("课表", systemImage: "calendar") }

            NavigationStack {
                TasksView(showingTaskEditor: $showingTaskEditor)
            }
            .tabItem { Label("待办", systemImage: "checklist") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
        .tint(AppTheme.accent)
        .environment(\.locale, Locale(identifier: "zh_CN"))
        .sheet(isPresented: $showingTaskEditor) {
            TaskEditorView()
                .environmentObject(store)
        }
        .alert("保存失败", isPresented: .constant(store.lastError != nil)) {
            Button("好") { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "未知错误")
        }
    }
}

extension Date {
    var shortDateTime: String {
        ChineseDateText.dateTime(self)
    }
}

