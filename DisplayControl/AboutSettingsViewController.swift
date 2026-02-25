import AppKit

class AboutSettingsViewController: NSViewController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 260))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // App icon
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        if let appIcon = NSApp.applicationIconImage {
            iconView.image = appIcon
        }
        iconView.imageScaling = .scaleProportionallyUpOrDown

        // App name
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Display Control"
        let nameLabel = NSTextField(labelWithString: appName)
        nameLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.alignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Version + build
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionLabel = NSTextField(labelWithString: "Version \(version) (\(build))")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Copyright
        let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
            ?? "© 2025 Flynsarmy"
        let copyrightLabel = NSTextField(labelWithString: copyright)
        copyrightLabel.font = NSFont.systemFont(ofSize: 11)
        copyrightLabel.textColor = .tertiaryLabelColor
        copyrightLabel.alignment = .center
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false

        // GitHub link button
        let githubButton = NSButton(title: "View on GitHub", target: self, action: #selector(openGitHub))
        githubButton.bezelStyle = .inline
        githubButton.translatesAutoresizingMaskIntoConstraints = false

        // Stack
        let stack = NSStackView(views: [iconView, nameLabel, versionLabel, copyrightLabel, githubButton])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])

        // Extra spacing between rows
        stack.setCustomSpacing(12, after: iconView)
        stack.setCustomSpacing(4, after: nameLabel)
        stack.setCustomSpacing(16, after: copyrightLabel)
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/Flynsarmy/osx-displaycontrol-app") {
            NSWorkspace.shared.open(url)
        }
    }
}
