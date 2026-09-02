import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var snapshot: AppSnapshot
    @Published var lastError: String?

    init() {
        snapshot = SharedDiskStore.load()
    }

    var schedule: TermSchedule { snapshot.schedule }

    var pendingTasks: [StudyTask] {
        snapshot.tasks
            .filter { !$0.isCompleted }
            .sorted { taskSortDate($0) < taskSortDate($1) }
    }

    func replaceSchedule(_ schedule: TermSchedule) {
        snapshot.schedule = schedule
        persist()
    }

    func upsertCourse(_ course: CourseSession) {
        if let index = snapshot.schedule.courses.firstIndex(where: { $0.id == course.id }) {
            snapshot.schedule.courses[index] = course
        } else {
            snapshot.schedule.courses.append(course)
        }
        persist()
    }

    func deleteCourse(id: UUID) {
        snapshot.schedule.courses.removeAll { $0.id == id }
        persist()
    }

    func upsertTask(_ task: StudyTask) {
        if let index = snapshot.tasks.firstIndex(where: { $0.id == task.id }) {
            snapshot.tasks[index] = task
        } else {
            snapshot.tasks.append(task)
        }
        persist()
    }

    func toggleTask(_ task: StudyTask) {
        guard let index = snapshot.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        snapshot.tasks[index].isCompleted.toggle()
        persist()
    }

    func deleteTasks(at offsets: IndexSet, from tasks: [StudyTask]) {
        let ids = Set(offsets.map { tasks[$0].id })
        snapshot.tasks.removeAll { ids.contains($0.id) }
        persist()
    }

    func resetToScreenshotSchedule() {
        snapshot.schedule = DefaultData.schedule
        persist()
    }

    private func persist() {
        snapshot.updatedAt = Date()
        do {
            try SharedDiskStore.save(snapshot)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func taskSortDate(_ task: StudyTask) -> Date {
        task.dueDate ?? task.scheduledStart ?? .distantFuture
    }
}

