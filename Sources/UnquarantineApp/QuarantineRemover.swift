import AppKit
import Darwin

enum QuarantineRemover {

    static func process(url: URL, recursive: Bool, removeMetadata: Bool, extract: Bool) -> String {
        let name = url.lastPathComponent

        let (ok, err) = removeAttribute("com.apple.quarantine", at: url, recursive: recursive)
        guard ok else { return "✗  \(name)\(err.isEmpty ? "" : ": \(err)")" }

        if removeMetadata {
            _ = removeAttribute("com.apple.metadata:kMDItemWhereFroms", at: url, recursive: recursive)
            _ = removeAttribute("com.apple.metadata:kMDItemDownloadedDate", at: url, recursive: recursive)
        }

        if extract {
            DispatchQueue.main.async { NSWorkspace.shared.open(url) }
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
        let result = path.withCString { cPath -> Int32 in
            name.withCString { cName -> Int32 in
                removexattr(cPath, cName, 0)
            }
        }
        if result == 0 { return (true, "") }
        if errno == ENOATTR { return (true, "") }  // attribute didn't exist — fine
        return (false, String(cString: strerror(errno)))
    }
}
