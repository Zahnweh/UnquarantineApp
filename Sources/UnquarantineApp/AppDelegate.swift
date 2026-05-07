import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPopover()
        setupStatusItem()
        setupAppMenu()
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
        if !UserDefaults.standard.bool(forKey: "runInBackground") {
            showMainWindow()
        }
        Updater.checkOnLaunch()
    }

    // MARK: - Setup

    private func setupPopover() {
        let vc = NSViewController()
        vc.view = DropZoneView(size: NSSize(width: 340, height: 340))

        popover = NSPopover()
        popover.contentViewController = vc
        popover.contentSize = NSSize(width: 340, height: 340)
        popover.behavior = .applicationDefined
        popover.animates = true
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        // 36×36px PNG is the @2x asset — set logical size to 18pt so it renders crisp on Retina
        if let icon = NSImage(named: "icon_tray_Template") {
            icon.size = NSSize(width: 18, height: 18)
            button.image = icon
        }

        button.action = #selector(handleClick(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupAppMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(NSMenuItem(title: "Über Unquarantine", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem(title: "Auf Updates prüfen…", action: #selector(checkUpdates), keyEquivalent: ""))
        appMenu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Main Window

    private func showMainWindow() {
        if mainWindow == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 340),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.title = "Unquarantine"
            win.center()
            win.isReleasedWhenClosed = false
            win.contentView = DropZoneView(size: NSSize(width: 340, height: 340))
            mainWindow = win
        }
        if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { showMainWindow() }
        return true
    }

    // MARK: - Status Item

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            guard let button = statusItem.button else { return }
            if #available(macOS 14.0, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Über Unquarantine", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Auf Updates prüfen…", action: #selector(checkUpdates), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: - Menu Actions

    @objc private func showAbout() {
        if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
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

    @objc func openSettings() {
        SettingsWindowController.shared.showAndFocus()
    }

    // MARK: - Finder-Dienste

    @objc func unquarantineFiles(_ pboard: NSPasteboard, userData: String,
                                  error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self],
                                            options: [.urlReadingFileURLsOnly: true]) as? [URL] else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            for url in urls {
                _ = QuarantineRemover.process(url: url, recursive: true, removeMetadata: true, extract: false)
            }
        }
    }

    @objc func unquarantineAndExtract(_ pboard: NSPasteboard, userData: String,
                                       error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self],
                                            options: [.urlReadingFileURLsOnly: true]) as? [URL] else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            for url in urls {
                _ = QuarantineRemover.process(url: url, recursive: true, removeMetadata: true, extract: true)
            }
        }
    }
}
