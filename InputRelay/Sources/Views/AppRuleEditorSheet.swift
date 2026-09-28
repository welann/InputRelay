import SwiftUI
import UniformTypeIdentifiers

struct AppRuleEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let existingRules: [AppRule]
    let onAdd: (AppRule) -> Bool
    @State private var runningApps: [NSRunningApplication] = []
    @State private var selectedName = ""
    @State private var ruleType: RuleType = .bundleID
    @State private var value = ""
    @State private var error: String?

    private enum RuleType: String, CaseIterable {
        case bundleID = "Bundle ID"
        case name = "应用名称"
    }

    private var candidate: AppRule? {
        (ruleType == .bundleID ? AppRule.bundleID(value) : .appName(value)).normalized
    }

    private var isDuplicate: Bool {
        guard let candidate else { return false }
        return existingRules.contains { $0.isEquivalent(to: candidate) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("添加应用规则")
                .font(.system(size: 20, weight: .semibold))
            Text("选择要使用此配置的应用，或手动填写匹配条件。")
                .foregroundStyle(AppTheme.secondary)
            HStack {
                Text("正在运行的应用")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Button("刷新列表", action: refreshApps)
                Button("浏览应用…", action: browseApplication)
            }
            ScrollView {
                VStack(spacing: 6) {
                    if runningApps.isEmpty {
                        Text("没有其他正在运行的应用，可浏览 .app 或手动输入。")
                            .foregroundStyle(AppTheme.secondary)
                            .padding()
                    }
                    ForEach(runningApps, id: \.processIdentifier) { app in
                        Button {
                            select(name: app.localizedName ?? "", bundleID: app.bundleIdentifier)
                        } label: {
                            HStack(spacing: 10) {
                                if let icon = app.icon {
                                    Image(nsImage: icon).resizable().frame(width: 28, height: 28)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(app.localizedName ?? "未命名应用")
                                    Text(app.bundleIdentifier ?? "按应用名称匹配")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppTheme.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 180)
            .background(AppTheme.inset)
            .cornerRadius(8)
            if !selectedName.isEmpty {
                Text("已选择：\(selectedName)")
                    .foregroundStyle(AppTheme.accent)
            }
            Picker("匹配方式", selection: Binding(get: { ruleType }, set: {
                ruleType = $0
                value = ""
                selectedName = ""
                error = nil
            })) {
                ForEach(RuleType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            TextField(ruleType == .bundleID ? "例如 com.apple.Safari" : "例如 Anki", text: $value)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("应用匹配条件")
            Text(ruleType == .bundleID ? "Bundle ID 精确匹配，不受应用显示名称变化影响。" : "应用名称使用包含匹配，不区分大小写。")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.secondary)
            if isDuplicate {
                Text("当前配置已包含这条规则，无需重复添加。")
                    .foregroundStyle(AppTheme.warning)
            } else if let error {
                Text(error).foregroundStyle(AppTheme.warning)
            }
            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.escape)
                Spacer()
                Button("添加") {
                    guard let candidate else { return }
                    if onAdd(candidate) { dismiss() } else { error = "规则未添加，请检查是否重复。" }
                }
                .keyboardShortcut(.return)
                .disabled(candidate == nil || isDuplicate)
            }
        }
        .padding(24)
        .frame(width: 520)
        .foregroundStyle(AppTheme.text)
        .background(AppTheme.surface)
        .onAppear(perform: refreshApps)
        .onChange(of: value) { _, _ in error = nil }
    }

    private func refreshApps() {
        runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isTerminated &&
            $0.processIdentifier != ProcessInfo.processInfo.processIdentifier &&
            $0.bundleIdentifier != "com.inputrelay.app"
        }.sorted { ($0.localizedName ?? "").localizedStandardCompare($1.localizedName ?? "") == .orderedAscending }
    }

    private func select(name: String, bundleID: String?) {
        selectedName = name
        if let bundleID, !bundleID.isEmpty {
            ruleType = .bundleID
            value = bundleID
        } else {
            ruleType = .name
            value = name
        }
        error = nil
    }

    private func browseApplication() {
        let panel = NSOpenPanel()
        panel.title = "选择目标应用"
        panel.prompt = "选择应用"
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let bundle = Bundle(url: url) else {
            error = "无法读取该应用，请手动填写名称或 Bundle ID。"
            return
        }
        select(name: FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: ""),
               bundleID: bundle.bundleIdentifier)
    }
}
