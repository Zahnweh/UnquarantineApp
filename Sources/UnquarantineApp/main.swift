import AppKit

let app = NSApplication.shared
let policy: NSApplication.ActivationPolicy = UserDefaults.standard.bool(forKey: "runInBackground") ? .accessory : .regular
app.setActivationPolicy(policy)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
