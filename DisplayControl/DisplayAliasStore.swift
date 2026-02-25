import Foundation
import CoreGraphics

/// Persists user-defined display aliases in UserDefaults.
/// Aliases only affect how displays are named inside this app.
class DisplayAliasStore {

    static let shared = DisplayAliasStore()

    private let defaults = UserDefaults.standard
    private let key = "DisplayAliases"

    private init() {}

    // MARK: - Public API

    /// Returns the alias for a display, or nil if none is set.
    func alias(for displayID: CGDirectDisplayID) -> String? {
        let dict = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        let value = dict[keyString(displayID)]
        return value?.isEmpty == false ? value : nil
    }

    /// Saves an alias for a display. Pass nil or empty string to clear.
    func setAlias(_ alias: String?, for displayID: CGDirectDisplayID) {
        var dict = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        if let alias = alias, !alias.isEmpty {
            dict[keyString(displayID)] = alias
        } else {
            dict.removeValue(forKey: keyString(displayID))
        }
        defaults.set(dict, forKey: key)
        NotificationCenter.default.post(name: .aliasesChanged, object: nil)
    }

    // MARK: - Private

    private func keyString(_ displayID: CGDirectDisplayID) -> String {
        return "\(displayID)"
    }
}

extension Notification.Name {
    static let aliasesChanged = Notification.Name("DisplayAliasesChanged")
}
