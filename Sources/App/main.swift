import AppKit

// Bootstrap NSApplication with our delegate for a headless accessory-style floating panel app.
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
