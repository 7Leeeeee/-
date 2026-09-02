import SwiftUI

struct CourseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    private let existingCourse: CourseSession?
    private let colors = [
        "#14B8A6", "#3B82F6", "#8B5CF6", "#EC4899",
        "#F97316", "#EAB308", "#22C55E", "#64748B"
    ]

    @State private var title: String
    @State private var courseCode: String
    @State private var weekday: Int
    @State private var startPeriod: Int
    @State private var endPeriod: Int
    @State private var firstWeek: Int
    @State private var lastWeek: Int
    @State private var campus: String
    @State private var room: String
    @State private var teacher: String
    @State private var colorHex: String
    @State private var note: String
    @State private var showingDeleteConfirmation = false

    init(course: CourseSession? = nil, schedule: TermSchedule) {
        existingCourse = course
        let firstPeriod = schedule.periods.first?.index ?? 1
        _title = State(initialValue: course?.title ?? "")
        _courseCode = State(initialValue: course?.courseCode ?? "")
        _weekday = State(initialValue: course?.weekday ?? 1)
        _startPeriod = State(initialValue: course?.startPeriod ?? firstPeriod)
        _endPeriod = State(initialValue: course?.endPeriod ?? firstPeriod)
        _firstWeek = State(initialValue: course?.weeks.min() ?? 1)
        _lastWeek = State(initialValue: course?.weeks.max() ?? schedule.totalWeeks)
        _campus = State(initialValue: course?.campus ?? "闵行校区")
        _room = State(initialValue: course?.room ?? "")
        _teacher = State(initialValue: course?.teacher ?? "")
        _colorHex = State(initialValue: course?.colorHex ?? "#3B82F6")
        _note = State(initialValue: course?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("课程信息") {
                    TextField("课程名称", text: $title)
                    TextField("课程代码", text: $courseCode)
                        .textInputAutocapitalization(.characters)
                    TextField("任课教师", text: $teacher)
                    TextField("校区", text: $campus)
                    TextField("教室", text: $room)
                    TextField("备注（可选）", text: $note, axis: .vertical)
                }

                Section("上课时间") {
                    Picker("星期", selection: $weekday) {
                        ForEach(1...7, id: \.self) { value in
                            Text(ScheduleEngine.weekdayName(value)).tag(value)
                        }
                    }

                    Picker("开始节次", selection: $startPeriod) {
                        ForEach(store.schedule.periods) { period in
                            Text("第\(period.index)节 · \(period.start)").tag(period.index)
                        }
                    }

                    Picker("结束节次", selection: $endPeriod) {
                        ForEach(store.schedule.periods.filter { $0.index >= startPeriod }) { period in
                            Text("第\(period.index)节 · \(period.end)").tag(period.index)
                        }
                    }
                }

                Section("上课周次") {
                    Stepper("从第 \(firstWeek) 周开始", value: $firstWeek, in: 1...lastWeek)
                    Stepper(
                        "到第 \(lastWeek) 周结束",
                        value: $lastWeek,
                        in: firstWeek...store.schedule.totalWeeks
                    )
                }

                Section("课程颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                colorHex = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if colorHex == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("选择课程颜色")
                        }
                    }
                    .padding(.vertical, 4)
                }

                if existingCourse != nil {
                    Section {
                        Button("删除这门课程", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(existingCourse == nil ? "添加课程" : "编辑课程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: startPeriod) { _, newValue in
                if endPeriod < newValue { endPeriod = newValue }
            }
            .confirmationDialog("确定删除这门课程？", isPresented: $showingDeleteConfirmation) {
                Button("删除课程", role: .destructive) { deleteCourse() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func save() {
        let course = CourseSession(
            id: existingCourse?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            courseCode: courseCode.trimmingCharacters(in: .whitespacesAndNewlines),
            weekday: weekday,
            startPeriod: startPeriod,
            endPeriod: max(startPeriod, endPeriod),
            weeks: Array(firstWeek...lastWeek),
            campus: campus.trimmingCharacters(in: .whitespacesAndNewlines),
            room: room.trimmingCharacters(in: .whitespacesAndNewlines),
            teacher: teacher.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.upsertCourse(course)
        dismiss()
    }

    private func deleteCourse() {
        guard let existingCourse else { return }
        store.deleteCourse(id: existingCourse.id)
        dismiss()
    }
}

