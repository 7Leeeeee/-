import Foundation
import UserNotifications

final class TaskNotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = TaskNotificationManager()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    func configureForegroundPresentation() {
        center.delegate = self
    }

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func schedule(_ task: StudyTask) async {
        await cancel(taskID: task.id)
        guard !task.isCompleted else { return }

        for (index, reminderDate) in task.reminderDates.sorted().enumerated()
            where reminderDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = task.kind == .exam ? "考试提醒" : "\(task.kind.title)提醒"
            content.body = task.title
            if !task.details.isEmpty { content.subtitle = task.details }
            content.sound = .default
            content.userInfo = ["taskID": task.id.uuidString]

            let components = ScheduleEngine.calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationID(task.id, index: index),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func refresh(tasks: [StudyTask]) async {
        for task in tasks {
            await schedule(task)
        }
    }

    func cancel(taskID: UUID) async {
        let prefix = notificationPrefix(taskID)
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0 == prefix || $0.hasPrefix("\(prefix)-") }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    private func notificationPrefix(_ id: UUID) -> String {
        "my-timetable-task-\(id.uuidString)"
    }

    private func notificationID(_ id: UUID, index: Int) -> String {
        "\(notificationPrefix(id))-\(index)"
    }
}

