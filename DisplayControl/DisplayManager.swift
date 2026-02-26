import Foundation
import CoreGraphics
import IOKit

// MARK: - Display Info Model

struct DisplayInfo {
    let id: CGDirectDisplayID
    let name: String        // aliased name (or hardware name if no alias set)
    let hardwareName: String
    let isBuiltIn: Bool
}

// MARK: - Display Manager

class DisplayManager {

    // MARK: - Enumerate displays

    func activeDisplays() -> [DisplayInfo] {
        return buildDisplayList(useAliases: true)
    }

    /// Returns displays with their raw hardware names only (used by Settings UI header column).
    func activeDisplaysHardwareNames() -> [DisplayInfo] {
        return buildDisplayList(useAliases: false)
    }

    private func buildDisplayList(useAliases: Bool) -> [DisplayInfo] {
        var displayCount: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &displayCount)

        guard displayCount > 0 else { return [] }

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetOnlineDisplayList(displayCount, &displayIDs, &displayCount)

        // Build a quick id->name map so mirrored displays can reference the master name.
        var hwNames: [CGDirectDisplayID: String] = [:]
        for id in displayIDs { hwNames[id] = hardwareName(for: id) }

        return displayIDs.map { id in
            let hw = hwNames[id] ?? hardwareName(for: id)
            let masterID = CGDisplayMirrorsDisplay(id)
            let isMirroring = masterID != kCGNullDirectDisplay

            // When useAliases is false (Settings UI) show the raw hardware name.
            // When useAliases is true (menu) append a mirroring hint.
            let baseName: String
            if useAliases {
                let alias = DisplayAliasStore.shared.alias(for: id)
                baseName = alias ?? hw
            } else {
                baseName = hw
            }

            let displayedName: String
            if isMirroring && useAliases {
                let masterName = hwNames[masterID].flatMap { DisplayAliasStore.shared.alias(for: masterID) ?? $0 } ?? baseName
                displayedName = "\(baseName) (Mirroring \(masterName))"
            } else {
                displayedName = baseName
            }

            return DisplayInfo(
                id: id,
                name: displayedName,
                hardwareName: hw,
                isBuiltIn: CGDisplayIsBuiltin(id) != 0
            )
        }
    }

    // MARK: - Display name resolution

    private func hardwareName(for displayID: CGDirectDisplayID) -> String {
        if let name = ioKitDisplayName(for: displayID) {
            return name
        }
        if CGDisplayIsBuiltin(displayID) != 0 {
            return "Built-in Display"
        }
        return "Display \(displayID)"
    }

    /// Walks the IOKit registry to find the IODisplayConnect entry for this display
    /// and reads its product name. Works on macOS 12+ where IOServicePortFromCGDisplayID
    /// was removed.
    private func ioKitDisplayName(for displayID: CGDirectDisplayID) -> String? {
        // CGDisplayUnitNumber maps to IOFBDependentIndex in the registry
        let unitNumber = CGDisplayUnitNumber(displayID)

        var iter: io_iterator_t = IO_OBJECT_NULL
        let kr = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iter
        )
        guard kr == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iter) }

        var service = IOIteratorNext(iter)
        while service != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iter)
            }

            // Match by unit number stored in the parent framebuffer
            var parent: io_service_t = IO_OBJECT_NULL
            IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent)
            if parent != IO_OBJECT_NULL {
                let unitProp = IORegistryEntryCreateCFProperty(
                    parent, "IOFBDependentIndex" as CFString, kCFAllocatorDefault, 0
                )?.takeRetainedValue() as? UInt32
                IOObjectRelease(parent)
                guard unitProp == unitNumber else { continue }
            }

            if let name = ioDisplayProductName(from: service) {
                return name
            }
        }
        return nil
    }

    private func ioDisplayProductName(from service: io_service_t) -> String? {
        guard let infoDict = IODisplayCreateInfoDictionary(
            service,
            IOOptionBits(kIODisplayOnlyPreferredName)
        )?.takeRetainedValue() as? [String: AnyObject] else {
            return nil
        }
        guard let productNames = infoDict[kDisplayProductName] as? [String: String] else {
            return nil
        }
        let locale = Locale.current.identifier
        if let name = productNames[locale] { return name }
        if let name = productNames["en_US"] { return name }
        return productNames.values.first
    }

    // MARK: - Display configuration

    func setExtended(displayID: CGDirectDisplayID) {
        applyConfiguration { config in
            CGConfigureDisplayMirrorOfDisplay(config, displayID, kCGNullDirectDisplay)
        }
    }

    func setMirror(displayID: CGDirectDisplayID, ofDisplay masterID: CGDirectDisplayID) {
        applyConfiguration { config in
            CGConfigureDisplayMirrorOfDisplay(config, displayID, masterID)
        }
    }

    private func applyConfiguration(_ block: (CGDisplayConfigRef) -> Void) {
        var config: CGDisplayConfigRef?
        let beginErr = CGBeginDisplayConfiguration(&config)
        guard beginErr == .success, let cfg = config else {
            NSLog("DisplayControl: Failed to begin display configuration: \(beginErr.rawValue)")
            return
        }
        block(cfg)
        let completeErr = CGCompleteDisplayConfiguration(cfg, .permanently)
        if completeErr != .success {
            NSLog("DisplayControl: Failed to complete display configuration: \(completeErr.rawValue)")
            CGCancelDisplayConfiguration(cfg)
        }
    }
}
