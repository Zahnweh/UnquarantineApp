import AppKit

// MARK: - DropZoneView

final class DropZoneView: NSView {

    override var isFlipped: Bool { true }

    private var isHovering = false
    private let imageView = NSImageView()
    private let statusField: NSTextField
    private let recursiveCheckbox: NSButton
    private let metadataCheckbox: NSButton
    private let extractCheckbox: NSButton

    init(size: NSSize) {
        statusField = NSTextField(wrappingLabelWithString: "")
        recursiveCheckbox = NSButton(checkboxWithTitle: "Rekursiv", target: nil, action: nil)
        metadataCheckbox = NSButton(checkboxWithTitle: "Herkunfts-Metadaten entfernen", target: nil, action: nil)
        extractCheckbox = NSButton(checkboxWithTitle: "Archiv entpacken", target: nil, action: nil)
        super.init(frame: NSRect(origin: .zero, size: size))
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true
        registerForDraggedTypes([.fileURL])

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 44, weight: .light)
        imageView.image = NSImage(systemSymbolName: "lock.slash", accessibilityDescription: nil)
        imageView.symbolConfiguration = symbolConfig
        imageView.contentTintColor = .tertiaryLabelColor
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "Quarantäne entfernen")
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let hintLabel = NSTextField(labelWithString: "Archive oder Ordner hierher ziehen")
        hintLabel.font = .systemFont(ofSize: 11.5)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.alignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        recursiveCheckbox.state = .on
        recursiveCheckbox.font = .systemFont(ofSize: 12)

        metadataCheckbox.state = .on
        metadataCheckbox.font = .systemFont(ofSize: 12)

        extractCheckbox.state = .off
        extractCheckbox.font = .systemFont(ofSize: 12)

        let checkboxStack = NSStackView(views: [recursiveCheckbox, metadataCheckbox, extractCheckbox])
        checkboxStack.orientation = .vertical
        checkboxStack.alignment = .leading
        checkboxStack.spacing = 6
        checkboxStack.translatesAutoresizingMaskIntoConstraints = false

        statusField.font = .monospacedSystemFont(ofSize: 10.5, weight: .regular)
        statusField.textColor = .secondaryLabelColor
        statusField.alignment = .center
        statusField.maximumNumberOfLines = 5
        statusField.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(hintLabel)
        addSubview(checkboxStack)
        addSubview(statusField)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 26),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            hintLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            checkboxStack.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 18),
            checkboxStack.centerXAnchor.constraint(equalTo: centerXAnchor),

            statusField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            statusField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let inset: CGFloat = 10
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let radius: CGFloat = 10

        if isHovering {
            NSColor.controlAccentColor.withAlphaComponent(0.08).setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
        }

        let border = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        border.lineWidth = 1.5
        border.setLineDash([8, 5], count: 2, phase: 0)
        (isHovering ? NSColor.controlAccentColor : NSColor.tertiaryLabelColor).setStroke()
        border.stroke()
    }

    // MARK: - Drag & Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard canAccept(sender) else { return [] }
        isHovering = true
        imageView.contentTintColor = .controlAccentColor
        needsDisplay = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHovering = false
        imageView.contentTintColor = .tertiaryLabelColor
        needsDisplay = true
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { true }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isHovering = false
        imageView.contentTintColor = .tertiaryLabelColor
        needsDisplay = true

        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty else { return false }

        let recursive = recursiveCheckbox.state == .on
        let removeMetadata = metadataCheckbox.state == .on
        let extract = extractCheckbox.state == .on

        statusField.textColor = .secondaryLabelColor
        statusField.stringValue = "Verarbeite \(urls.count) \(urls.count == 1 ? "Datei" : "Dateien")…"

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let lines = urls.map { Self.process(url: $0, recursive: recursive, removeMetadata: removeMetadata, extract: extract) }
            DispatchQueue.main.async {
                self?.statusField.textColor = .labelColor
                self?.statusField.stringValue = lines.joined(separator: "\n")
            }
        }
        return true
    }

    private func canAccept(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
    }

    // MARK: - xattr Helpers

    private static func runXattr(attribute: String, url: URL, recursive: Bool) -> (ok: Bool, error: String) {
        var args = ["-d"]
        if recursive { args.append("-r") }
        args += [attribute, url.path]

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        proc.arguments = args
        proc.standardOutput = Pipe()
        let errPipe = Pipe()
        proc.standardError = errPipe

        do {
            try proc.run()
            proc.waitUntilExit()
            if proc.terminationStatus == 0 { return (true, "") }
            let errStr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if errStr.contains("No such xattr") { return (true, "") }
            return (false, errStr)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private static func process(url: URL, recursive: Bool, removeMetadata: Bool, extract: Bool) -> String {
        let name = url.lastPathComponent

        let (ok, err) = runXattr(attribute: "com.apple.quarantine", url: url, recursive: recursive)
        guard ok else { return "✗  \(name)\(err.isEmpty ? "" : ": \(err)")" }

        if removeMetadata {
            _ = runXattr(attribute: "com.apple.metadata:kMDItemWhereFroms", url: url, recursive: recursive)
            _ = runXattr(attribute: "com.apple.metadata:kMDItemDownloadedDate", url: url, recursive: recursive)
        }

        if extract {
            DispatchQueue.main.async {
                NSWorkspace.shared.open(url)
            }
        }

        return "✓  \(name)"
    }
}

// MARK: - AppDelegate

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
    }

    private func setupMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(
            title: "Beenden",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        appItem.submenu = appMenu
        menu.addItem(appItem)
        NSApp.mainMenu = menu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.activate(ignoringOtherApps: true)
app.run()
