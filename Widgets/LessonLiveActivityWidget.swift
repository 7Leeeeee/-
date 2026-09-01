import ActivityKit
import SwiftUI
import WidgetKit

struct LessonLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LessonActivityAttributes.self) { context in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(widgetHex: context.attributes.colorHex))
                    .frame(width: 5)
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.phase).font(.caption.bold()).foregroundStyle(.secondary)
                    Text(context.attributes.courseTitle).font(.headline).lineLimit(1)
                    Label(context.attributes.room, systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(timerInterval: context.attributes.start...context.attributes.end, countsDown: true)
                    .font(.system(.body, design: .rounded).monospacedDigit().bold())
            }
            .padding()
            .activityBackgroundTint(Color(widgetHex: context.attributes.colorHex).opacity(0.14))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(Color(widgetHex: context.attributes.colorHex))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.start...context.attributes.end, countsDown: true)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.courseTitle).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label(context.attributes.room, systemImage: "mappin.and.ellipse")
                        Spacer()
                        Text(context.attributes.teacher)
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(Color(widgetHex: context.attributes.colorHex))
            } compactTrailing: {
                Text(timerInterval: context.attributes.start...context.attributes.end, countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "book.fill")
                    .foregroundStyle(Color(widgetHex: context.attributes.colorHex))
            }
            .widgetURL(URL(string: "mytimetable://today"))
            .keylineTint(Color(widgetHex: context.attributes.colorHex))
        }
    }
}
