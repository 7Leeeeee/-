import SwiftUI
import WidgetKit

struct TodayScheduleWidget: Widget {
    let kind = "TodayScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimetableProvider()) { entry in
            TodayScheduleWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "mytimetable://today"))
        }
        .configurationDisplayName("今日课表")
        .description("快速查看今天的课程和待办。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct TodayScheduleWidgetView: View {
    let entry: TimetableEntry

    private var courses: [CourseSession] {
        ScheduleEngine.sessions(on: entry.date, schedule: entry.snapshot.schedule)
    }

    private var tasks: [StudyTask] {
        entry.snapshot.tasks.filter { task in
            guard !task.isCompleted else { return false }
            return [task.scheduledStart, task.dueDate]
                .compactMap { $0 }
                .contains { ScheduleEngine.calendar.isDate($0, inSameDayAs: entry.date) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("今天").font(.headline)
                Spacer()
                Text(entry.date.formatted(.dateTime.month().day().weekday(.short)))
                    .font(.caption).foregroundStyle(.secondary)
            }

            if courses.isEmpty && tasks.isEmpty {
                ContentUnavailableView("今天没有安排", systemImage: "sparkles")
            } else {
                ForEach(courses.prefix(4)) { course in
                    HStack(spacing: 7) {
                        Circle().fill(Color(widgetHex: course.colorHex)).frame(width: 7, height: 7)
                        Text(course.title).font(.caption.bold()).lineLimit(1)
                        Spacer()
                        Text(course.room).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                ForEach(tasks.prefix(2)) { task in
                    HStack(spacing: 7) {
                        Image(systemName: task.kind.symbol).foregroundStyle(.blue)
                        Text(task.title).font(.caption).lineLimit(1)
                        Spacer()
                    }
                }
            }
        }
    }
}
