import AppKit

enum QuarantineRemover {

    static func process(url: URL, recursive: Bool, removeMetadata: Bool, extract: Bool) -> String {
        let name = url.lastPathComponent

        let (ok, err) = runXattr(attribute: "com.apple.quarantine", url: url, recursive: recursive)
        guard ok else { return "✗  \(name)\(err.isEmpty ? "" : ": \(err)")" }

        if removeMetadata {
            _ = runXattr(attribute: "com.apple.metadata:kMDItemWhereFroms", url: url, recursive: recursive)
            _ = runXattr(attribute: "com.apple.metadata:kMDItemDownloadedDate", url: url, recursive: recursive)
        }

        if extract {
            DispatchQueue.main.async { NSWorkspace.shared.open(url) }
        }

        return "✓  \(name)"
    }

    static func runXattr(attribute: String, url: URL, recursive: Bool) -> (ok: Bool, error: String) {
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
}
