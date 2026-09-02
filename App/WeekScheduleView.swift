import SwiftUI

private enum ScheduleContentMode: CaseIterable {
    case courses
    case combined
    case tasks

    var title: String {
        switch self {
        case .courses: "仅课程"
        case .combined: "课程与待办"
        case .tasks: "仅待办"
        }
    }

    var symbol: String {
        switch self {
        case .courses: "calendar"
        case .combined: "rectangle.split.2x1"
        case .tasks: "checklist"
        }
    }

    var next: Self {
        switch self {
        case .courses: .combined
        case .combined: .tasks
        case .tasks: .courses
        }
    }

    var showsCourses: Bool { self != .tasks }
    var showsTasks: Bool { self != .courses }
}

struct WeekScheduleView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var showingTaskEditor: Bool

    @State private var selectedWeek = 1
    @State private var contentMode: ScheduleContentMode = .courses
    @State private var zoomScale: CGFloat = 1
    @GestureState private var gestureScale: CGFloat = 1
    @State private var showingNewCourse = false
    @State private var selectedCourse: CourseSession?
    @State private var selectedTask: StudyTask?
    @State private var selectedTaskGroup: TaskGroupSelection?

    private let timeColumnWidth: CGFloat = 72
    private let baseRowHeight: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                weekPicker
                modeBanner
                scheduleCanvas(availableWidth: proxy.size.width)
            }
        }
        .background(AppTheme.background)
        .navigationTitle("课表")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) { contentMode = contentMode.next }
                } label: {
                    Image(systemName: contentMode.symbol)
                }
                .accessibilityLabel("当前显示\(contentMode.title)，点击切换")

                Menu {
                    Button {
                        showingNewCourse = true
                    } label: {
                        Label("添加课程", systemImage: "book.closed")
                    }
                    Button {
                        showingTaskEditor = true
                    } label: {
                        Label("添加待办", systemImage: "checklist")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("添加课程或待办")
            }
        }
        .onAppear {
            selectedWeek = ScheduleEngine.teachingWeek(
                on: Date(),
                schedule: store.schedule
            ) ?? 1
        }
        .sheet(isPresented: $showingNewCourse) {
            CourseEditorView(schedule: store.schedule)
                .environmentObject(store)
        }
        .sheet(item: $selectedCourse) { course in
            CourseEditorView(course: course, schedule: store.schedule)
                .environmentObject(store)
        }
        .sheet(item: $selectedTask) { task in
            TaskEditorView(existingTask: task)
                .environmentObject(store)
        }
        .sheet(item: $selectedTaskGroup) { group in
            TaskGroupSheet(tasks: group.tasks)
                .environmentObject(store)
        }
    }

    private var effectiveScale: CGFloat {
        min(1.65, max(0.72, zoomScale * gestureScale))
    }

    private var rowHeight: CGFloat { baseRowHeight * effectiveScale }

    private func dayWidth(availableWidth: CGFloat) -> CGFloat {
        let adaptiveBase = max(112, min(152, (availableWidth - timeColumnWidth) / 2.35))
        return adaptiveBase * effectiveScale
    }

    private var weekPicker: some View {
        HStack(spacing: 8) {
            Button {
                selectedWeek = max(1, selectedWeek - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedWeek == 1)

            Spacer(minLength: 0)
            VStack(spacing: 2) {
                Text("第 \(selectedWeek) 周").font(.headline)
                Text(weekDateRange).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)

            Menu {
                Button("缩小") { changeZoom(by: -0.12) }
                Button("恢复默认大小") { withAnimation(.snappy) { zoomScale = 1 } }
                Button("放大") { changeZoom(by: 0.12) }
            } label: {
                Label("\(Int(effectiveScale * 100))%", systemImage: "magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .frame(minWidth: 54, minHeight: 44)
            }

            Button {
                selectedWeek = min(store.schedule.totalWeeks, selectedWeek + 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedWeek == store.schedule.totalWeeks)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var modeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: contentMode.symbol)
            Text(contentMode.title).font(.caption.weight(.semibold))
            Spacer()
            Text("双指缩放 · 点课程可编辑")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(AppTheme.accent)
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(AppTheme.accent.opacity(0.08))
    }

    private func scheduleCanvas(availableWidth: CGFloat) -> some View {
        let width = dayWidth(availableWidth: availableWidth)
        return ScrollView(.vertical) {
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    Text("时间")
                        .font(.caption.bold())
                        .frame(width: timeColumnWidth, height: 48)
                        .background(Color(uiColor: .systemBackground))
                    periodColumn
                }
                .zIndex(2)
                .background(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 2, y: 0)

                ScrollView(.horizontal) {
                    VStack(spacing: 0) {
                        dayHeader(dayWidth: width)
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(1...7, id: \.self) { weekday in
                                dayColumn(weekday, dayWidth: width)
                            }
                        }
                    }
                    .simultaneousGesture(
                        MagnifyGesture()
                            .updating($gestureScale) { value, state, _ in
                                state = value.magnification
                            }
                            .onEnded { value in
                                zoomScale = min(1.65, max(0.72, zoomScale * value.magnification))
                            }
                    )
                }
                .scrollIndicators(.visible)
            }
        }
        .scrollIndicators(.visible)
    }

    private func dayHeader(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(1...7, id: \.self) { day in
                let date = ScheduleEngine.date(
                    forWeek: selectedWeek,
                    weekday: day,
                    schedule: store.schedule
                )
                VStack(spacing: 2) {
                    Text(ScheduleEngine.weekdayName(day)).font(.caption.bold())
                    Text(ChineseDateText.monthDay(date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: dayWidth, height: 48)
                .background(
                    ScheduleEngine.calendar.isDateInToday(date)
                        ? AppTheme.accent.opacity(0.12)
                        : Color(uiColor: .systemBackground)
                )
                .overlay(alignment: .leading) { Divider() }
            }
        }
    }

    private var periodColumn: some View {
        VStack(spacing: 0) {
            ForEach(store.schedule.periods) { period in
                VStack(spacing: 2) {
                    Text("第\(period.index)节").font(.caption.bold())
                    Text(period.start).font(.caption2).foregroundStyle(.secondary)
                    Text(period.end).font(.caption2).foregroundStyle(.tertiary)
                }
                .frame(width: timeColumnWidth, height: rowHeight)
                .background(periodBackground(period.index))
                .overlay(alignment: .bottom) { Divider() }
            }
        }
    }

    private func dayColumn(_ weekday: Int, dayWidth: CGFloat) -> some View {
        let courses = coursesFor(weekday: weekday)
        let taskSlots = taskSlotsFor(weekday: weekday)
        let courseLaneWidth = contentMode == .combined ? dayWidth * 0.62 : dayWidth
        let taskLaneWidth = contentMode == .combined ? dayWidth * 0.38 : dayWidth

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(store.schedule.periods) { _ in
                    Rectangle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(width: dayWidth, height: rowHeight)
                        .overlay(alignment: .bottom) { Divider() }
                }
            }

            if contentMode.showsCourses {
                ForEach(courses) { course in
                    Button {
                        selectedCourse = course
                    } label: {
                        courseCard(course)
                            .frame(
                                width: courseLaneWidth - 6,
                                height: CGFloat(course.endPeriod - course.startPeriod + 1) * rowHeight - 6,
                                alignment: .topLeading
                            )
                    }
                    .buttonStyle(.plain)
                    .offset(x: 3, y: CGFloat(course.startPeriod - 1) * rowHeight + 3)
                    .accessibilityLabel("编辑课程 \(course.title)")
                }
            }

            if contentMode.showsTasks {
                ForEach(taskSlots) { slot in
                    Button {
                        if slot.tasks.count == 1 {
                            selectedTask = slot.tasks[0]
                        } else {
                            selectedTaskGroup = TaskGroupSelection(tasks: slot.tasks)
                        }
                    } label: {
                        taskSlotCard(slot)
                            .frame(
                                width: taskLaneWidth - 6,
                                height: rowHeight - 6,
                                alignment: .topLeading
                            )
                    }
                    .buttonStyle(.plain)
                    .offset(
                        x: (contentMode == .combined ? courseLaneWidth : 0) + 3,
                        y: CGFloat(slot.row) * rowHeight + 3
                    )
                    .accessibilityLabel("查看该时间段的 \(slot.tasks.count) 条待办")
                }
            }
        }
        .frame(width: dayWidth, height: CGFloat(store.schedule.periods.count) * rowHeight)
        .overlay(alignment: .leading) { Divider() }
    }

    private func courseCard(_ course: CourseSession) -> some View {
        HStack(alignment: .top, spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: course.colorHex))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 3) {
                Text(course.title).font(.caption.bold()).lineLimit(3)
                Text(course.room).font(.caption2).lineLimit(1)
                Text(course.teacher).font(.caption2).lineLimit(1)
            }
        }
        .foregroundStyle(Color.primary)
        .padding(6)
        .background(
            Color(hex: course.colorHex).opacity(0.17),
            in: RoundedRectangle(cornerRadius: AppTheme.courseCorner)
        )
    }

    private func taskSlotCard(_ slot: TaskSlot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: "checklist")
                Text(slot.tasks.count == 1 ? slot.tasks[0].kind.title : "\(slot.tasks.count)项")
            }
            .font(.caption2.bold())

            ForEach(slot.tasks.prefix(effectiveScale >= 1.15 ? 2 : 1)) { task in
                Text(task.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }

            if slot.tasks.count > (effectiveScale >= 1.15 ? 2 : 1) {
                Text("还有 \(slot.tasks.count - (effectiveScale >= 1.15 ? 2 : 1)) 项")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(Color.primary)
        .padding(5)
        .background(
            AppTheme.accent.opacity(0.13),
            in: RoundedRectangle(cornerRadius: AppTheme.courseCorner)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.courseCorner)
                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
        }
    }

    private var weekDateRange: String {
        let start = ScheduleEngine.date(forWeek: selectedWeek, weekday: 1, schedule: store.schedule)
        let end = ScheduleEngine.date(forWeek: selectedWeek, weekday: 7, schedule: store.schedule)
        return "\(ChineseDateText.monthDay(start)) – \(ChineseDateText.monthDay(end))"
    }

    private func coursesFor(weekday: Int) -> [CourseSession] {
        store.schedule.courses.filter {
            $0.weekday == weekday && $0.weeks.contains(selectedWeek)
        }
    }

    private func tasksFor(weekday: Int) -> [StudyTask] {
        store.pendingTasks.filter { task in
            guard let start = task.scheduledStart,
                  let week = ScheduleEngine.teachingWeek(on: start, schedule: store.schedule)
            else { return false }
            return week == selectedWeek && ScheduleEngine.mondayBasedWeekday(on: start) == weekday
        }
    }

    private func taskSlotsFor(weekday: Int) -> [TaskSlot] {
        let grouped = Dictionary(grouping: tasksFor(weekday: weekday), by: rowForTask)
        return grouped.keys.sorted().map { row in
            TaskSlot(row: row, tasks: grouped[row, default: []].sorted {
                ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture)
            })
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
        return values.enumerated().min {
            abs($0.element - target) < abs($1.element - target)
        }?.offset ?? 0
    }

    private func periodBackground(_ index: Int) -> Color {
        index.isMultiple(of: 2)
            ? Color(uiColor: .secondarySystemGroupedBackground)
            : Color(uiColor: .systemGroupedBackground)
    }

    private func changeZoom(by delta: CGFloat) {
        withAnimation(.snappy) {
            zoomScale = min(1.65, max(0.72, zoomScale + delta))
        }
    }
}

private struct TaskSlot: Identifiable {
    let row: Int
    let tasks: [StudyTask]
    var id: Int { row }
}

private struct TaskGroupSelection: Identifiable {
    let id = UUID()
    let tasks: [StudyTask]
}

private struct TaskGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    let tasks: [StudyTask]
    @State private var selectedTask: StudyTask?

    var body: some View {
        NavigationStack {
            List(tasks) { task in
                Button {
                    selectedTask = task
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title).font(.body.weight(.semibold))
                        if let start = task.scheduledStart {
                            Text(start.shortDateTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("该时间段的待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskEditorView(existingTask: task)
                    .environmentObject(store)
            }
        }
    }
}

