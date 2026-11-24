import AppKit

@main
@MainActor
final class BatteryInfoMacApp: NSObject, NSApplicationDelegate {
    private var store: BluetoothBatteryStore?
    private var statusBarController: StatusBarController?

    static func main() {
        let app = NSApplication.shared
        let delegate = BatteryInfoMacApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // Menu bar only, no Dock icon
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = BluetoothBatteryStore()
        self.store = store
        self.statusBarController = StatusBarController(store: store)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
