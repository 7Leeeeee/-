import ActivityKit
import Foundation

enum LessonLiveActivityController {
    static func startForNow(schedule: TermSchedule) async -> String {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return "请在系统设置中允许“实时活动”。"
        }

        let now = Date()
        guard let lesson = ScheduleEngine.currentLesson(at: now, schedule: schedule)
            ?? ScheduleEngine.nextLesson(after: now, schedule: schedule)
        else {
            return "当前学期范围内没有找到下一节课。"
        }

        let course = lesson.0
        let interval = lesson.1
        let phase = interval.contains(now) ? "上课中" : "下一节"
        let minutes = max(0, Int((interval.end.timeIntervalSince(now) / 60).rounded(.up)))
        let attributes = LessonActivityAttributes(
            courseTitle: course.title,
            courseCode: course.courseCode,
            room: course.room,
            teacher: course.teacher,
            start: interval.start,
            end: interval.end,
            colorHex: course.colorHex
        )
        let state = LessonActivityAttributes.ContentState(
            phase: phase,
            remainingMinutes: minutes,
            nextTitle: nil,
            nextStart: nil
        )

        do {
            for activity in Activity<LessonActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: state,
                    staleDate: interval.end,
                    relevanceScore: 80
                ),
                pushType: nil
            )
            return "已显示“\(course.title)”的实时活动。"
        } catch {
            return "无法开启实时活动：\(error.localizedDescription)"
        }
    }
}
