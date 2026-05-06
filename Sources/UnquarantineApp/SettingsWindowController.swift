import AppKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {

    static let shared = SettingsWindowController()

    private lazy var backgroundCheckbox = makeCheckbox(
        "Im Hintergrund ausführen (kein Dock-Icon)",
        action: #selector(toggleBackground(_:))
    )
    private lazy var loginCheckbox = makeCheckbox(
        "Beim Login starten",
        action: #selector(toggleLoginItem(_:))
    )

    private init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 110),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Einstellungen"
        win.center()
        win.isReleasedWhenClosed = false
        super.init(window: win)
        setupContent()
    }

    required init?(coder: NSCoder) { nil }

    func showAndFocus() {
        backgroundCheckbox.state = UserDefaults.standard.bool(forKey: "runInBackground") ? .on : .off
        loginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func setupContent() {
        let stack = NSStackView(views: [backgroundCheckbox, loginCheckbox])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            container.trailingAnchor.constraint(greaterThanOrEqualTo: stack.trailingAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20)
        ])
        window?.contentView = container
    }

    private func makeCheckbox(_ title: String, action: Selector) -> NSButton {
        let btn = NSButton(checkboxWithTitle: title, target: self, action: action)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    @objc private func toggleBackground(_ sender: NSButton) {
        let background = sender.state == .on
        UserDefaults.standard.set(background, forKey: "runInBackground")
        NSApp.setActivationPolicy(background ? .accessory : .regular)
        if !background {
            if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        }
    }

    @objc private func toggleLoginItem(_ sender: NSButton) {
        do {
            if sender.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            sender.state = sender.state == .on ? .off : .on
        }
    }
}
