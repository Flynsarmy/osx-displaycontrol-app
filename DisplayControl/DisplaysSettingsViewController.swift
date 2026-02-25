import AppKit
import CoreGraphics

/// View controller for the "Displays" settings tab.
/// Lists every active display and lets the user enter a custom alias.
class DisplaysSettingsViewController: NSViewController {

    private var displays: [DisplayInfo] = []
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reload()

        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .displayConfigChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI

    private func setupUI() {
        // Description label
        let label = NSTextField(wrappingLabelWithString:
            "Assign a custom name to each display. These aliases are only used within this app.")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        // Table
        tableView = NSTableView()
        tableView.style = .inset
        tableView.rowHeight = 36

        let hwCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("hw"))
        hwCol.title = "Display"
        hwCol.minWidth = 160
        hwCol.resizingMask = .autoresizingMask

        let aliasCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("alias"))
        aliasCol.title = "Alias"
        aliasCol.minWidth = 180
        aliasCol.resizingMask = .autoresizingMask

        tableView.addTableColumn(hwCol)
        tableView.addTableColumn(aliasCol)
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsEmptySelection = true
        tableView.selectionHighlightStyle = .none

        scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Reset button
        let resetButton = NSButton(title: "Clear All Aliases", target: self, action: #selector(clearAll))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -12),

            resetButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    // MARK: - Data

    @objc private func reload() {
        displays = DisplayManager().activeDisplaysHardwareNames()
        tableView.reloadData()
    }

    @objc private func clearAll() {
        let alert = NSAlert()
        alert.messageText = "Clear All Aliases?"
        alert.informativeText = "All custom display names will be removed and hardware names will be used instead."
        alert.addButton(withTitle: "Clear All")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        guard let window = view.window else { return }
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self = self else { return }
            for display in self.displays {
                DisplayAliasStore.shared.setAlias(nil, for: display.id)
            }
            self.tableView.reloadData()
        }
    }
}

// MARK: - NSTableViewDataSource

extension DisplaysSettingsViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return displays.count
    }
}

// MARK: - NSTableViewDelegate

extension DisplaysSettingsViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < displays.count else { return nil }
        let display = displays[row]

        if tableColumn?.identifier.rawValue == "hw" {
            // Hardware name column (read-only)
            let cellId = NSUserInterfaceItemIdentifier("HWCell")
            var cell = tableView.makeView(withIdentifier: cellId, owner: self) as? NSTableCellView
            if cell == nil {
                cell = NSTableCellView()
                cell?.identifier = cellId
                let tf = NSTextField(labelWithString: "")
                tf.identifier = NSUserInterfaceItemIdentifier("text")
                tf.translatesAutoresizingMaskIntoConstraints = false
                cell?.addSubview(tf)
                cell?.textField = tf
                NSLayoutConstraint.activate([
                    tf.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                    tf.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                    tf.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                ])
            }
            cell?.textField?.stringValue = display.hardwareName
            return cell

        } else {
            // Alias column (editable)
            let cellId = NSUserInterfaceItemIdentifier("AliasCell")
            var cell = tableView.makeView(withIdentifier: cellId, owner: self) as? AliasCell
            if cell == nil {
                cell = AliasCell()
                cell?.identifier = cellId
            }
            cell?.configure(displayID: display.id,
                            placeholder: display.hardwareName,
                            currentAlias: DisplayAliasStore.shared.alias(for: display.id))
            return cell
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { 36 }
}

// MARK: - AliasCell

/// A table cell that owns an editable NSTextField for the alias.
private class AliasCell: NSTableCellView, NSTextFieldDelegate {

    private var displayID: CGDirectDisplayID = 0
    private let field: NSTextField

    override init(frame: NSRect) {
        field = NSTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.bezelStyle = .roundedBezel
        super.init(frame: frame)
        addSubview(field)
        textField = field
        field.delegate = self
        NSLayoutConstraint.activate([
            field.centerYAnchor.constraint(equalTo: centerYAnchor),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(displayID: CGDirectDisplayID, placeholder: String, currentAlias: String?) {
        self.displayID = displayID
        field.placeholderString = placeholder
        field.stringValue = currentAlias ?? ""
    }

    // Save on commit (Return key or focus-out)
    func controlTextDidEndEditing(_ obj: Notification) {
        DisplayAliasStore.shared.setAlias(field.stringValue, for: displayID)
    }
}
