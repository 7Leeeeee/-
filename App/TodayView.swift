import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var showingTaskEditor: Bool
    @State private var liveActivityMessage: String?

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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header

                if courses.isEmpty {
                    ContentUnavailableView(
                        "今天没有课",
                        systemImage: "cup.and.saucer.fill",
                        description: Text("可以给自己安排一段专注时间。")
                    )
                } else {
                    sectionTitle("课程", count: courses.count)
                    ForEach(courses) { course in
                        CourseListCard(course: course, schedule: store.schedule)
                    }
                }

                sectionTitle("待办与备忘", count: todayTasks.count)
                if todayTasks.isEmpty {
                    Button {
                        showingTaskEditor = true
                    } label: {
                        Label("添加今天的备忘", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(todayTasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                .font(.title2.bold())
            if let week = ScheduleEngine.teachingWeek(on: Date(), schedule: store.schedule) {
                Text("\(store.schedule.name) · 第 \(week) 周")
                    .foregroundStyle(.secondary)
            } else {
                Text(store.schedule.name)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Text("\(count)").font(.caption.bold()).foregroundStyle(.secondary)
        }
    }
}

struct CourseListCard: View {
    let course: CourseSession
    let schedule: TermSchedule

    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: course.colorHex))
                .frame(width: 5)
            VStack(alignment: .leading, spacing: 5) {
                Text(course.title).font(.headline)
                Text(ScheduleEngine.periodLabel(for: course, schedule: schedule))
                    .font(.subheadline)
                Label("\(course.campus) · \(course.room)", systemImage: "mappin.and.ellipse")
                Label(course.teacher, systemImage: "person.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct TaskRow: View {
    @EnvironmentObject private var store: AppStore
    let task: StudyTask

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTask(task)
                Task { await TaskNotificationManager.shared.cancel(taskID: task.id) }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(task.isCompleted)
                if let date = task.dueDate ?? task.scheduledStart {
                    Text(date.shortDateTime).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: task.kind.symbol).foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
