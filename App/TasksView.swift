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
                    TaskRow(task: task)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTask = task }
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
                        TaskRow(task: task)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTask = task }
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
}

