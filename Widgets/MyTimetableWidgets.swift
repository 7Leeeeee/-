import SwiftUI
import WidgetKit

@main
struct MyTimetableWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextLessonWidget()
        TodayScheduleWidget()
        LessonLiveActivityWidget()
    }
}

struct TimetableEntry: TimelineEntry {
    let date: Date
    let snapshot: AppSnapshot
}

struct TimetableProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry(date: Date(), snapshot: DefaultData.snapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> Void) {
        completion(TimetableEntry(date: Date(), snapshot: SharedDiskStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
        let snapshot = SharedDiskStore.load()
        let now = Date()
        let entries = (0..<24).compactMap { offset -> TimetableEntry? in
            guard let date = ScheduleEngine.calendar.date(byAdding: .minute, value: offset * 15, to: now)
            else { return nil }
            return TimetableEntry(date: date, snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

extension Color {
    init(widgetHex: String) {
        let cleaned = widgetHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
