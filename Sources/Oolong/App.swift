import SwiftUI
import AppKit

@main
struct EntryPoint {
    static func main() {
        if CommandLine.arguments.contains("--probe") {
            ProbeRunner.run()
            return
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

// 用 AppKit NSStatusItem + NSPopover 托管 SwiftUI 面板。
// 不用 SwiftUI MenuBarExtra：它在 SwiftPM 打包下经常不注册状态栏图标。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()

    func applicationWillTerminate(_ notification: Notification) {
        model.cleanup()   // 恢复 disablesleep，避免残留系统不睡
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model.start()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Oolong")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover.behavior = .transient
        popover.animates = true
        let host = NSHostingController(rootView: MenuContentView(model: model))
        host.sizingOptions = [.preferredContentSize]   // 把 SwiftUI 固有尺寸同步给 popover，避免内容被裁
        host.view.appearance = NSAppearance(named: .aqua)   // 固定浅色，保证暖米白配色不被深色模式翻转
        popover.contentViewController = host
        popover.appearance = NSAppearance(named: .aqua)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
