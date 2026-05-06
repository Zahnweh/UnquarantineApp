import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPopover()
        setupStatusItem()
        setupAppMenu()
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
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

        if let icon = NSImage(named: "MenuBarIcon") {
            icon.isTemplate = true
            button.image = icon
        } else {
            let img = NSImage(systemSymbolName: "lock.slash", accessibilityDescription: "Unquarantine")
            img?.isTemplate = true
            button.image = img
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
        appMenu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        NSApp.mainMenu = mainMenu
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
