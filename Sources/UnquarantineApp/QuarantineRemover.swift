import AppKit
import Darwin
import os.log

private let log = OSLog(subsystem: "de.extragroup.unquarantine", category: "xattr")

enum QuarantineRemover {

    static func process(url: URL, recursive: Bool, removeMetadata: Bool, extract: Bool) -> String {
        let name = url.lastPathComponent

        let (ok, err) = removeAttribute("com.apple.quarantine", at: url, recursive: recursive)
        if !ok {
            if err == "EPERM" {
                DispatchQueue.main.async { showAccessAlert() }
                return "✗  \(name): Zugriff verweigert (siehe Systemeinstellungen)"
            }
            return "✗  \(name)\(err.isEmpty ? "" : ": \(err)")"
        }

        if removeMetadata {
            _ = removeAttribute("com.apple.metadata:kMDItemWhereFroms", at: url, recursive: recursive)
            _ = removeAttribute("com.apple.metadata:kMDItemDownloadedDate", at: url, recursive: recursive)
        }

        if extract {
            if url.pathExtension.lowercased() == "zip" {
                let destination = url.deletingLastPathComponent()
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                proc.arguments = ["-xk", "--noqtn", url.path, destination.path]
                if (try? proc.run()) != nil { proc.waitUntilExit() }
                DispatchQueue.main.async { NSWorkspace.shared.open(destination) }
            } else {
                DispatchQueue.main.async { NSWorkspace.shared.open(url) }
            }
        }

        return "✓  \(name)"
    }

    private static func removeAttribute(_ attrName: String, at url: URL, recursive: Bool) -> (ok: Bool, error: String) {
        let (rootOK, rootErr) = stripXattr(attrName, from: url)

        if recursive {
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isSymbolicLinkKey],
                options: []
            ) else { return (rootOK, rootErr) }
            for case let child as URL in enumerator {
                _ = stripXattr(attrName, from: child)
            }
        }

        return (rootOK, rootErr)
    }

    private static func stripXattr(_ name: String, from url: URL) -> (ok: Bool, error: String) {
        let path = url.path

        // Try fd-based removal (uses drag-drop document consent, avoids TCC path check)
        let fd = path.withCString { open($0, O_WRONLY | O_NOFOLLOW) }
        os_log("open(%{public}@) → fd=%d errno=%d", log: log, type: .debug, path, fd, errno)

        if fd >= 0 {
            defer { close(fd) }
            let result = name.withCString { fremovexattr(fd, $0, 0) }
            os_log("fremovexattr → %d errno=%d", log: log, type: .debug, result, errno)
            if result == 0 || errno == ENOATTR { return (true, "") }
        }

        // Fallback: path-based syscall
        let result = path.withCString { cPath -> Int32 in
            name.withCString { removexattr(cPath, $0, 0) }
        }
        os_log("removexattr(%{public}@) → %d errno=%d", log: log, type: .debug, path, result, errno)

        if result == 0 { return (true, "") }
        if errno == ENOATTR { return (true, "") }
        if errno == EPERM || errno == EACCES { return (false, "EPERM") }
        return (false, String(cString: strerror(errno)))
    }

    private static func showAccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Zugriff verweigert"
        alert.informativeText = """
            Unquarantine benötigt Vollen Festplattenzugriff um Quarantäne-Flags zu entfernen.

            Systemeinstellungen → Datenschutz & Sicherheit → Voller Festplattenzugriff → Unquarantine aktivieren.
            """
        alert.addButton(withTitle: "Systemeinstellungen öffnen")
        alert.addButton(withTitle: "Schließen")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
            )
        }
    }
}
