import SwiftUI

struct WeekScheduleView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var showingTaskEditor: Bool
    @State private var selectedWeek = 1

    private let dayWidth: CGFloat = 128
    private let rowHeight: CGFloat = 58
    private let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    var body: some View {
        VStack(spacing: 0) {
            weekPicker
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    dayHeader
                    HStack(alignment: .top, spacing: 0) {
                        periodColumn
                        ForEach(1...7, id: \.self) { weekday in
                            dayColumn(weekday)
                        }
                    }
                }
            }
        }
        .background(AppTheme.background)
        .navigationTitle("课表")
        .toolbar {
            Button {
                showingTaskEditor = true
            } label: {
                Label("备忘", systemImage: "square.and.pencil")
            }
        }
        .onAppear {
            selectedWeek = ScheduleEngine.teachingWeek(
                on: Date(),
                schedule: store.schedule
            ) ?? 1
        }
    }

    private var weekPicker: some View {
        HStack {
            Button {
                selectedWeek = max(1, selectedWeek - 1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedWeek == 1)

            Spacer()
            VStack(spacing: 2) {
                Text("第 \(selectedWeek) 周").font(.headline)
                Text(weekDateRange).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()

            Button {
                selectedWeek = min(store.schedule.totalWeeks, selectedWeek + 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedWeek == store.schedule.totalWeeks)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var dayHeader: some View {
        HStack(spacing: 0) {
            Text("时间")
                .font(.caption.bold())
                .frame(width: 64, height: 46)
            ForEach(1...7, id: \.self) { day in
                let date = ScheduleEngine.date(
                    forWeek: selectedWeek,
                    weekday: day,
                    schedule: store.schedule
                )
                VStack(spacing: 2) {
                    Text(weekdays[day - 1]).font(.caption.bold())
                    Text(date.formatted(.dateTime.month().day()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: dayWidth, height: 46)
                .background(ScheduleEngine.calendar.isDateInToday(date) ? Color.accentColor.opacity(0.12) : .clear)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var periodColumn: some View {
        VStack(spacing: 0) {
            ForEach(store.schedule.periods) { period in
                VStack(spacing: 2) {
                    Text("第\(period.index)节").font(.caption.bold())
                    Text(period.start).font(.caption2).foregroundStyle(.secondary)
                    Text(period.end).font(.caption2).foregroundStyle(.tertiary)
                }
                .frame(width: 64, height: rowHeight)
                .background(periodBackground(period.index))
                .overlay(alignment: .bottom) { Divider() }
            }
        }
    }

    private func dayColumn(_ weekday: Int) -> some View {
        let courses = store.schedule.courses.filter {
            $0.weekday == weekday && $0.weeks.contains(selectedWeek)
        }
        let tasks = tasksFor(weekday: weekday)

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(store.schedule.periods) { _ in
                    Rectangle()
                        .fill(.background)
                        .frame(width: dayWidth, height: rowHeight)
                        .overlay(alignment: .bottom) { Divider() }
                }
            }

            ForEach(courses) { course in
                HStack(alignment: .top, spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: course.colorHex))
                        .frame(width: 3)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(course.title).font(.caption.bold()).lineLimit(2)
                        Text(course.room).font(.caption2).lineLimit(1)
                        Text(course.teacher).font(.caption2).lineLimit(1)
                    }
                }
                .foregroundStyle(Color(hex: course.colorHex).mix(with: .black, by: 0.42))
                .padding(6)
                .frame(
                    width: dayWidth - 6,
                    height: CGFloat(course.endPeriod - course.startPeriod + 1) * rowHeight - 6,
                    alignment: .topLeading
                )
                .background(Color(hex: course.colorHex).opacity(0.16), in: RoundedRectangle(cornerRadius: AppTheme.courseCorner))
                .offset(x: 3, y: CGFloat(course.startPeriod - 1) * rowHeight + 3)
            }

            ForEach(tasks) { task in
                HStack(spacing: 4) {
                    Image(systemName: task.kind.symbol)
                    Text(task.title).lineLimit(2)
                }
                .font(.caption2.bold())
                .padding(6)
                .frame(width: dayWidth - 10, alignment: .leading)
                .frame(minHeight: 38, alignment: .leading)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.courseCorner))
                .offset(x: 5, y: CGFloat(rowForTask(task)) * rowHeight + 10)
            }
        }
        .frame(width: dayWidth, height: CGFloat(store.schedule.periods.count) * rowHeight)
        .overlay(alignment: .leading) { Divider() }
    }

    private var weekDateRange: String {
        let start = ScheduleEngine.date(forWeek: selectedWeek, weekday: 1, schedule: store.schedule)
        let end = ScheduleEngine.date(forWeek: selectedWeek, weekday: 7, schedule: store.schedule)
        return "\(start.formatted(.dateTime.month().day())) – \(end.formatted(.dateTime.month().day()))"
    }

    private func tasksFor(weekday: Int) -> [StudyTask] {
        store.pendingTasks.filter { task in
            guard let start = task.scheduledStart,
                  let week = ScheduleEngine.teachingWeek(on: start, schedule: store.schedule)
            else { return false }
            return week == selectedWeek && ScheduleEngine.mondayBasedWeekday(on: start) == weekday
        }
    }

    private func rowForTask(_ task: StudyTask) -> Int {
        guard let date = task.scheduledStart else { return 0 }
        let hour = ScheduleEngine.calendar.component(.hour, from: date)
        let minute = ScheduleEngine.calendar.component(.minute, from: date)
        let target = hour * 60 + minute
        let values = store.schedule.periods.map { period -> Int in
            let parts = period.start.split(separator: ":").compactMap { Int($0) }
            return (parts.first ?? 8) * 60 + (parts.last ?? 0)
        }
        return values.enumerated().min(by: { abs($0.element - target) < abs($1.element - target) })?.offset ?? 0
    }

    private func periodBackground(_ index: Int) -> Color {
        index.isMultiple(of: 2)
            ? Color(uiColor: .secondarySystemGroupedBackground)
            : Color(uiColor: .systemGroupedBackground)
    }
}

private extension Color {
    func mix(with other: Color, by fraction: Double) -> Color {
        self.opacity(max(0.55, 1 - fraction))
    }
}

