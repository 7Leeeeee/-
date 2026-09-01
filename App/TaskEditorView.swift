import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var title = ""
    @State private var details = ""
    @State private var kind: TaskKind = .todo
    @State private var courseCode = ""
    @State private var hasScheduledTime = true
    @State private var scheduledStart = Date().addingTimeInterval(3600)
    @State private var scheduledEnd = Date().addingTimeInterval(7200)
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var hasReminder = true
    @State private var reminderDate = Date().addingTimeInterval(1800)
    private let existingTask: StudyTask?

    init(existingTask: StudyTask? = nil) {
        self.existingTask = existingTask
        guard let task = existingTask else { return }
        _title = State(initialValue: task.title)
        _details = State(initialValue: task.details)
        _kind = State(initialValue: task.kind)
        _courseCode = State(initialValue: task.courseCode ?? "")
        _hasScheduledTime = State(initialValue: task.scheduledStart != nil)
        _scheduledStart = State(initialValue: task.scheduledStart ?? Date())
        _scheduledEnd = State(initialValue: task.scheduledEnd ?? task.scheduledStart?.addingTimeInterval(3600) ?? Date().addingTimeInterval(3600))
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date().addingTimeInterval(86400))
        _hasReminder = State(initialValue: task.reminderDate != nil)
        _reminderDate = State(initialValue: task.reminderDate ?? Date().addingTimeInterval(1800))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("标题，例如：提交生化作业", text: $title)
                    TextField("补充说明", text: $details, axis: .vertical)
                    Picker("类型", selection: $kind) {
                        ForEach(TaskKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.symbol).tag(kind)
                        }
                    }
                    TextField("关联课程代码（可选）", text: $courseCode)
                        .textInputAutocapitalization(.characters)
                }

                Section("安排到课表") {
                    Toggle("指定时间段", isOn: $hasScheduledTime)
                    if hasScheduledTime {
                        DatePicker("开始", selection: $scheduledStart)
                        DatePicker("结束", selection: $scheduledEnd, in: scheduledStart...)
                    }
                }

                Section("截止与提醒") {
                    Toggle("设置 DDL", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("截止时间", selection: $dueDate)
                    }
                    Toggle("弹窗提醒", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("提醒时间", selection: $reminderDate)
                    }
                }
            }
            .navigationTitle(existingTask == nil ? "新建待办" : "编辑待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let task = StudyTask(
            id: existingTask?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details,
            kind: kind,
            courseCode: courseCode.isEmpty ? nil : courseCode,
            scheduledStart: hasScheduledTime ? scheduledStart : nil,
            scheduledEnd: hasScheduledTime ? scheduledEnd : nil,
            dueDate: hasDueDate ? dueDate : nil,
            reminderDate: hasReminder ? reminderDate : nil,
            isCompleted: existingTask?.isCompleted ?? false,
            createdAt: existingTask?.createdAt ?? Date()
        )
        store.upsertTask(task)
        Task { await TaskNotificationManager.shared.schedule(task) }
        dismiss()
    }
}
