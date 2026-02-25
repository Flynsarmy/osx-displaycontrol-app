import AppKit

/// The Settings window, containing a tab view with Displays and About tabs.
class SettingsWindowController: NSWindowController {

    static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Display Control Settings"
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        window.minSize = NSSize(width: 440, height: 320)

        super.init(window: window)

        let tabView = NSTabView(frame: window.contentView!.bounds)
        tabView.autoresizingMask = [.width, .height]

        // Displays tab
        let displaysVC = DisplaysSettingsViewController()
        let displaysItem = NSTabViewItem(viewController: displaysVC)
        displaysItem.label = "Displays"
        tabView.addTabViewItem(displaysItem)

        // About tab
        let aboutVC = AboutSettingsViewController()
        let aboutItem = NSTabViewItem(viewController: aboutVC)
        aboutItem.label = "About"
        tabView.addTabViewItem(aboutItem)

        window.contentView?.addSubview(tabView)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
