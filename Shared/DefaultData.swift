import Foundation

enum DefaultData {
    static let periods: [ClassPeriod] = [
        .init(index: 1, start: "08:00", end: "08:45"),
        .init(index: 2, start: "08:50", end: "09:35"),
        .init(index: 3, start: "09:50", end: "10:35"),
        .init(index: 4, start: "10:40", end: "11:25"),
        .init(index: 5, start: "11:30", end: "12:15"),
        .init(index: 6, start: "13:00", end: "13:45"),
        .init(index: 7, start: "13:50", end: "14:35"),
        .init(index: 8, start: "14:50", end: "15:35"),
        .init(index: 9, start: "15:40", end: "16:25"),
        .init(index: 10, start: "16:30", end: "17:15"),
        .init(index: 11, start: "18:00", end: "18:45"),
        .init(index: 12, start: "18:50", end: "19:35"),
        .init(index: 13, start: "19:40", end: "20:25"),
        .init(index: 14, start: "20:30", end: "21:15"),
    ]

    static let schedule = TermSchedule(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "2026–2027 秋季学期",
        startDate: date(2026, 9, 14),
        totalWeeks: 18,
        periods: periods,
        courses: [
            course(
                id: 101,
                title: "生物化学",
                code: "BIOL2108.01",
                weekday: 1,
                periods: 3...4,
                weeks: 1...8,
                room: "闵四教202",
                teacher: "孙运彦",
                color: "#14B8A6"
            ),
            course(
                id: 102,
                title: "生物化学",
                code: "BIOL2108.01",
                weekday: 1,
                periods: 3...4,
                weeks: 9...16,
                room: "闵四教202",
                teacher: "阳怀宇",
                color: "#14B8A6"
            ),
            course(
                id: 103,
                title: "神话、信仰与社会传奇—宗教的社会人类学解释",
                code: "SOCI2730.01",
                weekday: 1,
                periods: 11...13,
                weeks: 1...12,
                room: "闵二教104",
                teacher: "陈赟",
                color: "#C08457"
            ),
            course(
                id: 104,
                title: "生物统计学",
                code: "BIOL2128.01",
                weekday: 3,
                periods: 3...5,
                weeks: 1...11,
                room: "闵二教104",
                teacher: "陈迎",
                color: "#3B82F6"
            ),
            course(
                id: 105,
                title: "生物统计学",
                code: "BIOL2128.01",
                weekday: 3,
                periods: 3...5,
                weeks: 12...16,
                room: "闵二教104",
                teacher: "赵磊",
                color: "#3B82F6"
            ),
            course(
                id: 106,
                title: "生物化学",
                code: "BIOL2108.01",
                weekday: 4,
                periods: 1...2,
                weeks: 1...8,
                room: "闵四教202",
                teacher: "孙运彦",
                color: "#14B8A6"
            ),
            course(
                id: 107,
                title: "生物化学",
                code: "BIOL2108.01",
                weekday: 4,
                periods: 1...2,
                weeks: 9...16,
                room: "闵四教202",
                teacher: "阳怀宇",
                color: "#14B8A6"
            ),
            course(
                id: 108,
                title: "大学物理B（一）",
                code: "PHYS2652.03",
                weekday: 4,
                periods: 3...5,
                weeks: 1...16,
                room: "闵四教229",
                teacher: "潘丽坤",
                color: "#64748B"
            ),
            course(
                id: 109,
                title: "马克思主义基本原理",
                code: "MARX1003.31",
                weekday: 4,
                periods: 11...13,
                weeks: 1...16,
                room: "闵一教109",
                teacher: "王馨曼",
                color: "#A855F7"
            ),
            course(
                id: 110,
                title: "体育与健康--网球（初）",
                code: "SPOR1024.06",
                weekday: 5,
                periods: 3...4,
                weeks: 1...16,
                room: "闵东网球场1",
                teacher: "陈赢",
                color: "#F97316"
            ),
            course(
                id: 111,
                title: "生物化学实验",
                code: "BIOL2110.02 #4",
                weekday: 5,
                periods: 6...9,
                weeks: 2...15,
                room: "闵实验B楼324",
                teacher: "何云东",
                color: "#65A30D"
            ),
        ]
    )

    static let snapshot = AppSnapshot(
        schedule: schedule,
        tasks: [],
        updatedAt: Date()
    )

    private static func course(
        id: Int,
        title: String,
        code: String,
        weekday: Int,
        periods: ClosedRange<Int>,
        weeks: ClosedRange<Int>,
        room: String,
        teacher: String,
        color: String
    ) -> CourseSession {
        let suffix = String(format: "%012d", id)
        return CourseSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(suffix)")!,
            title: title,
            courseCode: code,
            weekday: weekday,
            startPeriod: periods.lowerBound,
            endPeriod: periods.upperBound,
            weeks: Array(weeks),
            campus: "闵行校区",
            room: room,
            teacher: teacher,
            colorHex: color,
            note: ""
        )
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        ScheduleEngine.calendar.date(
            from: DateComponents(year: year, month: month, day: day)
        )!
    }
}
