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
        .tint(Color(hex: "#2779F5"))
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

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red, green, blue: Double
        if cleaned.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        } else {
            red = 0.15
            green = 0.48
            blue = 0.95
        }
        self.init(red: red, green: green, blue: blue)
    }
}

extension Date {
    var shortDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
