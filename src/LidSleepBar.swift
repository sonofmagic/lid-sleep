import Cocoa
import ServiceManagement

struct LidStatus {
    var enabled = false
    var source = "未知"
    var percent = "?"
    var nopass = false
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var status = LidStatus()

    private var lidSleepPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/lid-sleep").path
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageOnly
            button.toolTip = "合盖不睡"
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        refresh()
        let timer = Timer(timeInterval: 4, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        refresh()
        rebuildMenu(menu)
    }

    private func refresh() {
        let result = runLid(["status", "--machine"])
        if result.code == 0 {
            status = parse(result.output)
        }
        updateIcon()
    }

    private func updateIcon() {
        let symbol = status.enabled ? "cup.and.saucer.fill" : "moon.zzz"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "合盖不睡")
        image?.isTemplate = true
        if let image, let configured = image.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        ) {
            configured.isTemplate = true
            statusItem.button?.image = configured
        } else {
            statusItem.button?.image = image
        }
        let state = status.enabled ? "开" : "关"
        statusItem.button?.toolTip = "合盖不睡：\(state)"
    }

    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        addDisabled(menu, "合盖不睡：\(status.enabled ? "开" : "关")")
        addDisabled(menu, "电源：\(displaySource(status.source))")
        addDisabled(menu, "电量：\(status.percent)")
        addDisabled(menu, status.nopass ? "免密：已授权" : "免密：未授权")
        menu.addItem(.separator())

        if !status.nopass {
            addAction(menu, title: "授权免密…", action: #selector(authorize))
            menu.addItem(.separator())
        }

        let actionTitle = status.enabled ? "恢复合盖休眠" : "开启合盖不睡"
        addAction(menu, title: actionTitle, action: #selector(toggleAwake))
        menu.addItem(.separator())

        let login = addAction(menu, title: "登录时打开", action: #selector(toggleLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(.separator())

        addDisabled(menu, "退出后休眠设置仍保留")
        addAction(menu, title: "退出", action: #selector(quitApp), key: "q")
    }

    @discardableResult
    private func addAction(
        _ menu: NSMenu,
        title: String,
        action: Selector,
        key: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
        return item
    }

    private func addDisabled(_ menu: NSMenu, _ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func displaySource(_ source: String) -> String {
        switch source {
        case "AC Power": return "电源适配器"
        case "Battery Power": return "电池"
        default: return source
        }
    }

    @objc private func toggleAwake() {
        if status.enabled {
            apply(["off"])
            return
        }
        if status.source == "Battery Power" && !confirmBattery() {
            return
        }
        apply(status.source == "Battery Power" ? ["on", "--force"] : ["on"])
    }

    @objc private func authorize() {
        apply(["--gui", "install"])
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            showAlert(title: "无法设置登录项", text: error.localizedDescription)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func confirmBattery() -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "当前是电池供电"
        alert.informativeText = "合盖不睡会耗电发热，不要把电脑放进包里。仍要开启吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "仍然开启")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func apply(_ args: [String]) {
        let result = runLid(args)
        if result.code != 0 {
            let text = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            showAlert(title: "设置失败", text: text.isEmpty ? "lid-sleep 返回 \(result.code)" : text)
        }
        refresh()
    }

    private func showAlert(title: String, text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private func parse(_ text: String) -> LidStatus {
        var parsed = LidStatus()
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let value = String(parts[1])
            switch key {
            case "enabled": parsed.enabled = value == "1"
            case "source": parsed.source = value
            case "percent": parsed.percent = value
            case "nopass": parsed.nopass = value == "1"
            default: break
            }
        }
        return parsed
    }

    private func runLid(_ args: [String]) -> (code: Int32, output: String) {
        guard FileManager.default.isExecutableFile(atPath: lidSleepPath) else {
            return (127, "找不到 \(lidSleepPath)")
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: lidSleepPath)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return (1, error.localizedDescription)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (task.terminationStatus, output)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
