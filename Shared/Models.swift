import ActivityKit
import Foundation

enum TaskKind: String, Codable, CaseIterable, Identifiable {
    case homework
    case exam
    case todo
    case memo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homework: "作业"
        case .exam: "考试"
        case .todo: "待办"
        case .memo: "备忘"
        }
    }

    var symbol: String {
        switch self {
        case .homework: "book.closed.fill"
        case .exam: "pencil.and.list.clipboard"
        case .todo: "checklist"
        case .memo: "note.text"
        }
    }
}

struct ClassPeriod: Codable, Hashable, Identifiable {
    let index: Int
    var start: String
    var end: String

    var id: Int { index }
}

struct CourseSession: Codable, Hashable, Identifiable {
    var id: UUID
    var title: String
    var courseCode: String
    /// 1 = Monday ... 7 = Sunday.
    var weekday: Int
    var startPeriod: Int
    var endPeriod: Int
    var weeks: [Int]
    var campus: String
    var room: String
    var teacher: String
    var colorHex: String
    var note: String

    func isActive(in week: Int, weekday targetWeekday: Int) -> Bool {
        weekday == targetWeekday && weeks.contains(week)
    }
}

struct TermSchedule: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    /// The Monday of teaching week 1.
    var startDate: Date
    var totalWeeks: Int
    var periods: [ClassPeriod]
    var courses: [CourseSession]
}

struct StudyTask: Codable, Hashable, Identifiable {
    var id: UUID
    var title: String
    var details: String
    var kind: TaskKind
    var courseCode: String?
    var scheduledStart: Date?
    var scheduledEnd: Date?
    var dueDate: Date?
    var reminderDate: Date?
    var isCompleted: Bool
    var createdAt: Date
}

struct AppSnapshot: Codable, Hashable {
    var schedule: TermSchedule
    var tasks: [StudyTask]
    var updatedAt: Date
}

struct ScheduleImportEnvelope: Codable {
    let schemaVersion: Int
    let generatedAt: Date
    let source: String
    let schedule: TermSchedule
}

struct LessonActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: String
        var remainingMinutes: Int
        var nextTitle: String?
        var nextStart: Date?
    }

    var courseTitle: String
    var courseCode: String
    var room: String
    var teacher: String
    var start: Date
    var end: Date
    var colorHex: String
}
