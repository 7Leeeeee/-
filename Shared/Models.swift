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
    var reminderDates: [Date]
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID,
        title: String,
        details: String,
        kind: TaskKind,
        courseCode: String?,
        scheduledStart: Date?,
        scheduledEnd: Date?,
        dueDate: Date?,
        reminderDates: [Date],
        isCompleted: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.kind = kind
        self.courseCode = courseCode
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.dueDate = dueDate
        self.reminderDates = reminderDates.sorted()
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, details, kind, courseCode, scheduledStart, scheduledEnd
        case dueDate, reminderDates, reminderDate, isCompleted, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        details = try container.decode(String.self, forKey: .details)
        kind = try container.decode(TaskKind.self, forKey: .kind)
        courseCode = try container.decodeIfPresent(String.self, forKey: .courseCode)
        scheduledStart = try container.decodeIfPresent(Date.self, forKey: .scheduledStart)
        scheduledEnd = try container.decodeIfPresent(Date.self, forKey: .scheduledEnd)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        if let dates = try container.decodeIfPresent([Date].self, forKey: .reminderDates) {
            reminderDates = dates.sorted()
        } else if let legacyDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate) {
            reminderDates = [legacyDate]
        } else {
            reminderDates = []
        }
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(details, forKey: .details)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(courseCode, forKey: .courseCode)
        try container.encodeIfPresent(scheduledStart, forKey: .scheduledStart)
        try container.encodeIfPresent(scheduledEnd, forKey: .scheduledEnd)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(reminderDates.sorted(), forKey: .reminderDates)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
    }
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

