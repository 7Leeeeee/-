import SwiftUI
import WidgetKit

struct NextLessonWidget: Widget {
    let kind = "NextLessonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimetableProvider()) { entry in
            NextLessonWidgetView(entry: entry)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "mytimetable://today"))
        }
        .configurationDisplayName("下一节课")
        .description("只显示今天正在进行或即将开始的课程，不跨天预告。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

private struct NextLessonWidgetView: View {
    let entry: TimetableEntry

    private var todayCourses: [CourseSession] {
        ScheduleEngine.sessions(on: entry.date, schedule: entry.snapshot.schedule)
    }

    var body: some View {
        if let lesson = ScheduleEngine.currentOrNextLessonToday(
            at: entry.date,
            schedule: entry.snapshot.schedule
        ) {
            lessonView(
                course: lesson.0,
                interval: lesson.1,
                phase: lesson.1.contains(entry.date) ? "上课中" : "下一节"
            )
        } else if todayCourses.isEmpty {
            emptyView(title: "今天没课", detail: ChineseDateText.monthDayWeekday(entry.date))
        } else {
            emptyView(title: "今天课程已结束", detail: "可以安排复习或休息")
        }
    }

    private func emptyView(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.green)
            Text(title).font(.headline)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func lessonView(
        course: CourseSession,
        interval: DateInterval,
        phase: String
    ) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(widgetHex: course.colorHex))
                .frame(width: 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(phase).font(.caption.bold()).foregroundStyle(.secondary)
                Text(course.title).font(.headline).lineLimit(2)
                Text(course.room).font(.caption).lineLimit(1)
                Text("\(ScheduleEngine.weekdayName(ScheduleEngine.mondayBasedWeekday(on: interval.start))) · \(ChineseDateText.time(interval.start))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

