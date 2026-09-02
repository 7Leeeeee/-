import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var showingTaskEditor: Bool
    @State private var liveActivityMessage: String?
    @State private var selectedTask: StudyTask?

    private var courses: [CourseSession] {
        ScheduleEngine.sessions(on: Date(), schedule: store.schedule)
    }

    private var todayTasks: [StudyTask] {
        store.pendingTasks.filter { task in
            [task.scheduledStart, task.dueDate]
                .compactMap { $0 }
                .contains { ScheduleEngine.calendar.isDateInToday($0) }
        }
    }

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 10, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                if courses.isEmpty {
                    ContentUnavailableView(
                        "今天没有课",
                        systemImage: "cup.and.saucer.fill",
                        description: Text("可以给自己安排一段专注时间。")
                    )
                } else {
                    ForEach(courses) { course in
                        CourseListCard(course: course, schedule: store.schedule)
                    }
                }
            } header: {
                sectionTitle("课程", count: courses.count)
            }

            Section {
                if todayTasks.isEmpty {
                    Button {
                        showingTaskEditor = true
                    } label: {
                        Label("添加今天的备忘", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                } else {
                    ForEach(todayTasks) { task in
                        TaskRow(
                            task: task,
                            onToggle: { toggle(task) },
                            onEdit: { selectedTask = task }
                        )
                    }
                }
            } header: {
                sectionTitle("待办与备忘", count: todayTasks.count)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("今天")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task {
                        liveActivityMessage = await LessonLiveActivityController.startForNow(
                            schedule: store.schedule
                        )
                    }
                } label: {
                    Image(systemName: "wave.3.right.circle")
                }
                .accessibilityLabel("开启课程灵动岛")

                Button {
                    showingTaskEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("添加待办")
            }
        }
        .alert("灵动岛", isPresented: .constant(liveActivityMessage != nil)) {
            Button("好") { liveActivityMessage = nil }
        } message: {
            Text(liveActivityMessage ?? "")
        }
        .sheet(item: $selectedTask) { task in
            TaskEditorView(existingTask: task)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ChineseDateText.monthDayWeekday(Date.now))
                    .font(.title2.weight(.bold))
                if let week = ScheduleEngine.teachingWeek(on: Date(), schedule: store.schedule) {
                    Text("\(store.schedule.name) · 第 \(week) 周")
                        .foregroundStyle(.secondary)
                } else {
                    Text(store.schedule.name)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(spacing: 0) {
                Text(ChineseDateText.day(Date.now))
                    .font(.title2.weight(.bold))
                Text(ChineseDateText.month(Date.now))
                    .font(.caption2.monospaced().weight(.semibold))
            }
            .foregroundStyle(AppTheme.accent)
            .frame(width: 54, height: 58)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.rowCorner)
                    .stroke(AppTheme.accent, lineWidth: 1)
            }
        }
        .padding(.vertical, 2)
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Text("\(count)").font(.caption.bold()).foregroundStyle(.secondary)
        }
    }

    private func toggle(_ task: StudyTask) {
        store.toggleTask(task)
        Task {
            if task.isCompleted {
                var pending = task
                pending.isCompleted = false
                await TaskNotificationManager.shared.schedule(pending)
            } else {
                await TaskNotificationManager.shared.cancel(taskID: task.id)
            }
        }
    }
}

struct CourseListCard: View {
    let course: CourseSession
    let schedule: TermSchedule

    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: course.colorHex))
                .frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 5) {
                Text(course.title).font(.body.weight(.semibold))
                Text(ScheduleEngine.periodLabel(for: course, schedule: schedule))
                    .font(.subheadline)
                Label("\(course.campus) · \(course.room)", systemImage: "mappin.and.ellipse")
                Label(course.teacher, systemImage: "person.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }
}

struct TaskRow: View {
    let task: StudyTask
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "标记为未完成" : "标记为已完成")

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Label(task.kind.title, systemImage: task.kind.symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        if let courseCode = task.courseCode, !courseCode.isEmpty {
                            Text(courseCode)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(task.title)
                        .font(.body.weight(.semibold))
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(.primary)
                    if let date = task.dueDate ?? task.scheduledStart {
                        Text(date.shortDateTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !task.reminderDates.isEmpty {
                        Label("\(task.reminderDates.count) 次提醒", systemImage: "bell")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("编辑 \(task.title)")
        }
        .padding(.vertical, 4)
    }
}

