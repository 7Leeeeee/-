import SwiftUI
import WidgetKit

struct TodayScheduleWidget: Widget {
    let kind = "TodayScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimetableProvider()) { entry in
            TodayOverviewWidgetView(entry: entry)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "mytimetable://today"))
        }
        .configurationDisplayName("今日总览")
        .description("同时查看下一节课、当天课表和当天注意事项。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct TodayOverviewWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimetableEntry

    private var courses: [CourseSession] {
        ScheduleEngine.sessions(on: entry.date, schedule: entry.snapshot.schedule)
    }

    private var tasks: [StudyTask] {
        entry.snapshot.tasks
            .filter { task in
                guard !task.isCompleted else { return false }
                return [task.scheduledStart, task.dueDate]
                    .compactMap { $0 }
                    .contains { ScheduleEngine.calendar.isDate($0, inSameDayAs: entry.date) }
            }
            .sorted {
                ($0.scheduledStart ?? $0.dueDate ?? .distantFuture)
                    < ($1.scheduledStart ?? $1.dueDate ?? .distantFuture)
            }
    }

    private var nextLesson: (CourseSession, DateInterval)? {
        ScheduleEngine.currentOrNextLessonToday(
            at: entry.date,
            schedule: entry.snapshot.schedule
        )
    }

    var body: some View {
        Group {
            if family == .systemLarge {
                largeLayout
            } else {
                mediumLayout
            }
        }
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            HStack(alignment: .top, spacing: 10) {
                nextLessonSummary
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                VStack(alignment: .leading, spacing: 7) {
                    compactCourses(limit: 2)
                    compactTasks(limit: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 11) {
            header
            nextLessonSummary
                .padding(9)
                .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
            Divider()
            compactCourses(limit: 4)
            Divider()
            compactTasks(limit: 3)
            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        HStack {
            Text("今日总览").font(.headline)
            Spacer()
            Text(ChineseDateText.monthDayWeekday(entry.date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var nextLessonSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("下一节课", systemImage: "clock")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if let nextLesson {
                Text(nextLesson.0.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text("\(ScheduleEngine.weekdayName(ScheduleEngine.mondayBasedWeekday(on: nextLesson.1.start))) · \(ChineseDateText.time(nextLesson.1.start))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(nextLesson.0.room)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if courses.isEmpty {
                Text("今天没课").font(.subheadline.bold())
            } else {
                Text("今日课程已结束").font(.subheadline.bold())
            }
        }
    }

    @ViewBuilder
    private func compactCourses(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("当天课表 · \(courses.count)", systemImage: "calendar")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if courses.isEmpty {
                Text("今天没有课程")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(courses.prefix(limit)) { course in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(widgetHex: course.colorHex))
                            .frame(width: 6, height: 6)
                        Text(course.title).font(.caption2.bold()).lineLimit(1)
                        Spacer(minLength: 2)
                        Text(course.room).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                if courses.count > limit {
                    Text("还有 \(courses.count - limit) 节")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func compactTasks(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("注意事项 · \(tasks.count)", systemImage: "checklist")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if tasks.isEmpty {
                Text("今天没有待办")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tasks.prefix(limit)) { task in
                    HStack(spacing: 5) {
                        Image(systemName: task.kind.symbol)
                            .foregroundStyle(Color.accentColor)
                        Text(task.title).font(.caption2).lineLimit(1)
                    }
                }
                if tasks.count > limit {
                    Text("还有 \(tasks.count - limit) 项")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

