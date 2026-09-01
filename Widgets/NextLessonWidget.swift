import SwiftUI
import WidgetKit

struct NextLessonWidget: Widget {
    let kind = "NextLessonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimetableProvider()) { entry in
            NextLessonWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "mytimetable://today"))
        }
        .configurationDisplayName("下一节课")
        .description("显示当前课程或下一节课的时间与教室。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

private struct NextLessonWidgetView: View {
    let entry: TimetableEntry

    var body: some View {
        if let current = ScheduleEngine.currentLesson(at: entry.date, schedule: entry.snapshot.schedule) {
            lessonView(course: current.0, interval: current.1, phase: "上课中")
        } else if let next = ScheduleEngine.nextLesson(after: entry.date, schedule: entry.snapshot.schedule) {
            lessonView(course: next.0, interval: next.1, phase: "下一节")
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("近期没有课").font(.headline)
                Text("去完成一个待办吧").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func lessonView(course: CourseSession, interval: DateInterval, phase: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(widgetHex: course.colorHex))
                .frame(width: 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(phase).font(.caption.bold()).foregroundStyle(.secondary)
                Text(course.title).font(.headline).lineLimit(2)
                Text(course.room).font(.caption).lineLimit(1)
                Text(interval.start.formatted(date: .omitted, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
