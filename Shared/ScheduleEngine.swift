import Foundation

enum ScheduleEngine {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

    static func teachingWeek(on date: Date, schedule: TermSchedule) -> Int? {
        let start = calendar.startOfDay(for: schedule.startDate)
        let target = calendar.startOfDay(for: date)
        guard let days = calendar.dateComponents([.day], from: start, to: target).day,
              days >= 0
        else { return nil }

        let week = days / 7 + 1
        return (1...schedule.totalWeeks).contains(week) ? week : nil
    }

    static func mondayBasedWeekday(on date: Date) -> Int {
        let appleWeekday = calendar.component(.weekday, from: date)
        return appleWeekday == 1 ? 7 : appleWeekday - 1
    }

    static func date(forWeek week: Int, weekday: Int, schedule: TermSchedule) -> Date {
        calendar.date(
            byAdding: .day,
            value: (week - 1) * 7 + (weekday - 1),
            to: calendar.startOfDay(for: schedule.startDate)
        ) ?? schedule.startDate
    }

    static func sessions(on date: Date, schedule: TermSchedule) -> [CourseSession] {
        guard let week = teachingWeek(on: date, schedule: schedule) else { return [] }
        let weekday = mondayBasedWeekday(on: date)
        return schedule.courses
            .filter { $0.isActive(in: week, weekday: weekday) }
            .sorted { $0.startPeriod < $1.startPeriod }
    }

    static func dateInterval(
        for course: CourseSession,
        week: Int,
        schedule: TermSchedule
    ) -> DateInterval? {
        guard let firstPeriod = schedule.periods.first(where: { $0.index == course.startPeriod }),
              let lastPeriod = schedule.periods.first(where: { $0.index == course.endPeriod })
        else { return nil }

        let day = date(forWeek: week, weekday: course.weekday, schedule: schedule)
        guard let start = date(on: day, clock: firstPeriod.start),
              let end = date(on: day, clock: lastPeriod.end)
        else { return nil }
        return DateInterval(start: start, end: end)
    }

    static func nextLesson(after date: Date, schedule: TermSchedule) -> (CourseSession, DateInterval)? {
        guard let currentWeek = teachingWeek(on: date, schedule: schedule) ?? inferredNearbyWeek(on: date, schedule: schedule)
        else { return nil }

        let lowerWeek = max(1, currentWeek)
        let upperWeek = min(schedule.totalWeeks, currentWeek + 2)
        var candidates: [(CourseSession, DateInterval)] = []

        for week in lowerWeek...upperWeek {
            for course in schedule.courses where course.weeks.contains(week) {
                if let interval = dateInterval(for: course, week: week, schedule: schedule),
                   interval.end > date {
                    candidates.append((course, interval))
                }
            }
        }
        return candidates.min { $0.1.start < $1.1.start }
    }

    static func currentOrNextLessonToday(
        at date: Date,
        schedule: TermSchedule
    ) -> (CourseSession, DateInterval)? {
        sessions(on: date, schedule: schedule)
            .compactMap { course -> (CourseSession, DateInterval)? in
                guard let week = teachingWeek(on: date, schedule: schedule),
                      let interval = dateInterval(for: course, week: week, schedule: schedule),
                      interval.end > date
                else { return nil }
                return (course, interval)
            }
            .min { $0.1.start < $1.1.start }
    }

    static func currentLesson(at date: Date, schedule: TermSchedule) -> (CourseSession, DateInterval)? {
        guard let week = teachingWeek(on: date, schedule: schedule) else { return nil }
        for course in sessions(on: date, schedule: schedule) {
            if let interval = dateInterval(for: course, week: week, schedule: schedule),
               interval.contains(date) {
                return (course, interval)
            }
        }
        return nil
    }

    static func periodLabel(for course: CourseSession, schedule: TermSchedule) -> String {
        let start = schedule.periods.first(where: { $0.index == course.startPeriod })?.start ?? ""
        let end = schedule.periods.first(where: { $0.index == course.endPeriod })?.end ?? ""
        return "第\(course.startPeriod)–\(course.endPeriod)节 · \(start)–\(end)"
    }

    static func weekdayName(_ weekday: Int) -> String {
        guard (1...7).contains(weekday) else { return "" }
        return ["周一", "周二", "周三", "周四", "周五", "周六", "周日"][weekday - 1]
    }

    private static func date(on day: Date, clock: String) -> Date? {
        let values = clock.split(separator: ":").compactMap { Int($0) }
        guard values.count == 2 else { return nil }
        return calendar.date(
            bySettingHour: values[0],
            minute: values[1],
            second: 0,
            of: day
        )
    }

    private static func inferredNearbyWeek(on date: Date, schedule: TermSchedule) -> Int? {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: schedule.startDate),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        let week = days / 7 + 1
        return week <= schedule.totalWeeks + 2 ? max(1, week) : nil
    }
}

enum ChineseDateText {
    static func monthDayWeekday(_ date: Date) -> String {
        string(date, format: "M月d日 EEEE")
    }

    static func monthDay(_ date: Date) -> String {
        string(date, format: "M月d日")
    }

    static func day(_ date: Date) -> String {
        string(date, format: "d")
    }

    static func month(_ date: Date) -> String {
        string(date, format: "M月")
    }

    static func weekdayTime(_ date: Date) -> String {
        string(date, format: "EEEE HH:mm")
    }

    static func dateTime(_ date: Date) -> String {
        string(date, format: "M月d日 EEEE HH:mm")
    }

    static func time(_ date: Date) -> String {
        string(date, format: "HH:mm")
    }

    private static func string(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = ScheduleEngine.calendar
        formatter.timeZone = ScheduleEngine.calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

