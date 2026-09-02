import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var showingTaskEditor: Bool
    @State private var selectedTask: StudyTask?

    private var completed: [StudyTask] {
        store.snapshot.tasks.filter(\.isCompleted).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section("进行中") {
                if store.pendingTasks.isEmpty {
                    ContentUnavailableView(
                        "没有待办",
                        systemImage: "checkmark.circle",
                        description: Text("作业、考试、DDL 和时间段备忘都可以放在这里。")
                    )
                }
                ForEach(store.pendingTasks) { task in
                    TaskRow(
                        task: task,
                        onToggle: { toggle(task) },
                        onEdit: { selectedTask = task }
                    )
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            toggle(task)
                        } label: {
                            Label("完成", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            selectedTask = task
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(AppTheme.accent)
                    }
                }
                .onDelete { offsets in
                    let removed = offsets.map { store.pendingTasks[$0] }
                    store.deleteTasks(at: offsets, from: store.pendingTasks)
                    Task {
                        for task in removed {
                            await TaskNotificationManager.shared.cancel(taskID: task.id)
                        }
                    }
                }
            }

            if !completed.isEmpty {
                Section("已完成") {
                    ForEach(completed) { task in
                        TaskRow(
                            task: task,
                            onToggle: { toggle(task) },
                            onEdit: { selectedTask = task }
                        )
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                toggle(task)
                            } label: {
                                Label("恢复", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.orange)
                        }
                    }
                    .onDelete { store.deleteTasks(at: $0, from: completed) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("待办与备忘")
        .toolbar {
            Button {
                showingTaskEditor = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskEditorView(existingTask: task)
                .environmentObject(store)
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

