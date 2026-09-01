import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingImport = false
    @State private var showingReset = false
    @State private var statusMessage: String?

    var body: some View {
        List {
            Section("课表数据") {
                LabeledContent("学期", value: store.schedule.name)
                LabeledContent("第一周", value: store.schedule.startDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("课程记录", value: "\(store.schedule.courses.count) 条")

                Button {
                    showingImport = true
                } label: {
                    Label("粘贴截图导入码", systemImage: "text.viewfinder")
                }

                Button {
                    exportCurrentSchedule()
                } label: {
                    Label("复制当前课表导入码", systemImage: "doc.on.doc")
                }

                Button(role: .destructive) {
                    showingReset = true
                } label: {
                    Label("恢复本次截图课表", systemImage: "arrow.counterclockwise")
                }
            }

            Section("提醒与系统交互") {
                Button {
                    Task {
                        let allowed = await TaskNotificationManager.shared.requestPermission()
                        statusMessage = allowed ? "提醒权限已开启。" : "提醒权限未开启，请到系统设置中允许通知。"
                    }
                } label: {
                    Label("开启弹窗提醒", systemImage: "bell.badge.fill")
                }
                LabeledContent("灵动岛", value: "在“今天”页面开启")
                LabeledContent("小组件", value: "安装后长按主屏幕添加")
            }

            Section("关于当前数据") {
                Text("已按截图识别 14 个节次和 11 条分周课程记录。第一周暂按上海交通大学官方安排设置为 2026 年 9 月 14 日。")
                Text("截图导入前会先显示学期名称、课程数量和节次数量，只有确认后才替换当前课表。")
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showingImport) {
            ImportScheduleView()
                .environmentObject(store)
        }
        .confirmationDialog("恢复截图中的初始课表？", isPresented: $showingReset) {
            Button("恢复", role: .destructive) { store.resetToScreenshotSchedule() }
            Button("取消", role: .cancel) {}
        }
        .alert("提示", isPresented: .constant(statusMessage != nil)) {
            Button("好") { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func exportCurrentSchedule() {
        let envelope = ScheduleImportEnvelope(
            schemaVersion: 1,
            generatedAt: Date(),
            source: "我的课表 iOS",
            schedule: store.schedule
        )
        do {
            UIPasteboard.general.string = try ScheduleImportCode.encode(envelope)
            statusMessage = "当前课表导入码已复制。"
        } catch {
            statusMessage = "生成失败：\(error.localizedDescription)"
        }
    }
}

struct ImportScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State private var code = ""
    @State private var preview: ScheduleImportEnvelope?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("导入码") {
                    TextEditor(text: $code)
                        .frame(minHeight: 150)
                        .font(.system(.caption, design: .monospaced))
                    HStack {
                        Button("从剪贴板粘贴") {
                            code = UIPasteboard.general.string ?? ""
                            decode()
                        }
                        Spacer()
                        Button("解析") { decode() }
                            .buttonStyle(.borderedProminent)
                    }
                }

                if let preview {
                    Section("导入预览") {
                        LabeledContent("学期", value: preview.schedule.name)
                        LabeledContent("第一周", value: preview.schedule.startDate.formatted(date: .abbreviated, time: .omitted))
                        LabeledContent("节次", value: "\(preview.schedule.periods.count)")
                        LabeledContent("课程记录", value: "\(preview.schedule.courses.count)")
                        LabeledContent("来源", value: preview.source)
                    }
                    Section {
                        Button("确认替换当前课表", role: .destructive) {
                            store.replaceSchedule(preview.schedule)
                            dismiss()
                        }
                    } footer: {
                        Text("待办和备忘不会被删除。")
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("截图导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func decode() {
        do {
            preview = try ScheduleImportCode.decode(code)
            errorMessage = nil
        } catch {
            preview = nil
            errorMessage = error.localizedDescription
        }
    }
}
