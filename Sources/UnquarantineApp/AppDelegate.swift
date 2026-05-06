import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()

        let size = NSSize(width: 340, height: 340)
        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Unquarantine"
        win.isReleasedWhenClosed = false
        win.contentView = DropZoneView(size: size)
        win.center()
        win.makeKeyAndOrderFront(nil)
        window = win

        Updater.checkOnLaunch()
    }

    private func setupMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(NSMenuItem(title: "Über Unquarantine", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Auf Updates prüfen…", action: #selector(checkUpdates), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        appItem.submenu = appMenu
        menu.addItem(appItem)
        NSApp.mainMenu = menu
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Unquarantine",
            .applicationVersion: Updater.version,
            .version: "",
            .credits: NSAttributedString(
                string: "Entfernt Quarantäne-Flags von Dateien und Archiven.",
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
            )
        ])
    }

    @objc private func checkUpdates() {
        Updater.checkManually()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
