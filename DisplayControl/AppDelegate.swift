import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var displayManager = DisplayManager()
    private var identifyOverlay = IdentifyOverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "display", accessibilityDescription: "Displays") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "🖥"
            }
            button.toolTip = "Display Control"
        }

        // Rebuild menu whenever it's about to open
        statusItem.menu = buildMenu()

        // Listen for display configuration changes
        CGDisplayRegisterReconfigurationCallback({ _, _, _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .displayConfigChanged, object: nil)
            }
        }, nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigChanged),
            name: .displayConfigChanged,
            object: nil
        )

        // Rebuild menu when aliases change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigChanged),
            name: .aliasesChanged,
            object: nil
        )
    }

    @objc private func displayConfigChanged() {
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let displays = displayManager.activeDisplays()

        // --- Identify row ---
        let identifyItem = NSMenuItem(
            title: "Identify Displays",
            action: #selector(identifyDisplays),
            keyEquivalent: ""
        )
        identifyItem.target = self
        if let icon = NSImage(systemSymbolName: "display.2", accessibilityDescription: nil) {
            icon.isTemplate = true
            identifyItem.image = icon
        }
        identifyItem.isEnabled = !displays.isEmpty
        menu.addItem(identifyItem)
        menu.addItem(.separator())

        // --- Display list ---
        if displays.isEmpty {
            let item = NSMenuItem(title: "No displays found", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for display in displays {
                let displayItem = NSMenuItem(title: display.name, action: nil, keyEquivalent: "")
                displayItem.submenu = buildSubmenu(for: display, allDisplays: displays)
                menu.addItem(displayItem)
            }
        }

        menu.addItem(.separator())

        // --- Settings ---
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    private func buildSubmenu(for display: DisplayInfo, allDisplays: [DisplayInfo]) -> NSMenu {
        let submenu = NSMenu()

        // --- Extended Display (normal, standalone) ---
        let extendedItem = NSMenuItem(
            title: "Extended Display",
            action: #selector(setExtended(_:)),
            keyEquivalent: ""
        )
        extendedItem.target = self
        extendedItem.representedObject = display.id
        // Check if currently NOT mirroring
        let currentMaster = CGDisplayMirrorsDisplay(display.id)
        extendedItem.state = (currentMaster == kCGNullDirectDisplay) ? .on : .off
        submenu.addItem(extendedItem)

        // --- Mirror options ---
        let others = allDisplays.filter { $0.id != display.id }
        if !others.isEmpty {
            submenu.addItem(.separator())
            for other in others {
                let mirrorItem = NSMenuItem(
                    title: "Mirror of \(other.name)",
                    action: #selector(setMirror(_:)),
                    keyEquivalent: ""
                )
                mirrorItem.target = self
                // Store [this display id, master display id]
                mirrorItem.representedObject = [display.id, other.id] as [CGDirectDisplayID]
                // Check if currently mirroring this specific display
                mirrorItem.state = (currentMaster == other.id) ? .on : .off
                submenu.addItem(mirrorItem)
            }
        }

        return submenu
    }

    // MARK: - Actions

    @objc private func identifyDisplays() {
        let displays = displayManager.activeDisplays()
        identifyOverlay.show(displays: displays)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func setExtended(_ sender: NSMenuItem) {
        guard let displayID = sender.representedObject as? CGDirectDisplayID else { return }
        displayManager.setExtended(displayID: displayID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.statusItem.menu = self.buildMenu()
        }
    }

    @objc private func setMirror(_ sender: NSMenuItem) {
        guard let ids = sender.representedObject as? [CGDirectDisplayID],
              ids.count == 2 else { return }
        displayManager.setMirror(displayID: ids[0], ofDisplay: ids[1])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.statusItem.menu = self.buildMenu()
        }
    }
}

extension Notification.Name {
    static let displayConfigChanged = Notification.Name("DisplayConfigChanged")
}
