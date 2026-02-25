import AppKit

/// Shows a translucent overlay with a large display number on every active display
/// for a few seconds, then auto-dismisses. Style inspired by Windows' Identify Displays.
class IdentifyOverlayController {

    private var windows: [NSWindow] = []

    func show(displays: [DisplayInfo]) {
        dismissAll()

        for (index, display) in displays.enumerated() {
            let screenFrame = CGDisplayBounds(display.id)

            // Convert CG coordinates (bottom-left origin) to NS coordinates (bottom-left on main screen)
            let nsFrame = convertToNSCoordinates(screenFrame)

            let window = makeOverlayWindow(frame: nsFrame)
            let view = makeContentView(
                number: index + 1,
                name: display.name,
                frame: CGRect(origin: .zero, size: nsFrame.size)
            )
            window.contentView = view
            window.orderFrontRegardless()
            windows.append(window)
        }

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.dismissAll()
        }
    }

    func dismissAll() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    // MARK: - Helpers

    private func convertToNSCoordinates(_ cgRect: CGRect) -> CGRect {
        // CG uses bottom-left origin on the primary display.
        // NS uses bottom-left origin of the primary screen.
        guard let primaryScreen = NSScreen.screens.first else { return cgRect }
        let primaryHeight = primaryScreen.frame.height
        return CGRect(
            x: cgRect.origin.x,
            y: primaryHeight - cgRect.origin.y - cgRect.height,
            width: cgRect.width,
            height: cgRect.height
        )
    }

    private func makeOverlayWindow(frame: CGRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver          // floats above everything
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        return window
    }

    private func makeContentView(number: Int, name: String, frame: CGRect) -> NSView {
        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor

        // Pill-shaped card centred on the display
        let cardWidth: CGFloat = 340
        let cardHeight: CGFloat = 220
        let cardX = (frame.width - cardWidth) / 2
        let cardY = (frame.height - cardHeight) / 2
        let cardFrame = CGRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight)

        let card = NSVisualEffectView(frame: cardFrame)
        card.material = .hudWindow
        card.blendingMode = .behindWindow
        card.state = .active
        card.wantsLayer = true
        card.layer?.cornerRadius = 28
        card.layer?.masksToBounds = true

        // Large display number
        let numberLabel = NSTextField(labelWithString: "\(number)")
        numberLabel.font = NSFont.systemFont(ofSize: 108, weight: .bold)
        numberLabel.textColor = .white
        numberLabel.alignment = .center
        numberLabel.sizeToFit()
        numberLabel.frame = CGRect(
            x: (cardWidth - numberLabel.frame.width) / 2,
            y: cardHeight - numberLabel.frame.height - 20,
            width: numberLabel.frame.width,
            height: numberLabel.frame.height
        )

        // Display name subtitle
        let nameLabel = NSTextField(labelWithString: name)
        nameLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = NSColor.white.withAlphaComponent(0.75)
        nameLabel.alignment = .center
        nameLabel.maximumNumberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.frame = CGRect(x: 16, y: 18, width: cardWidth - 32, height: 44)

        card.addSubview(numberLabel)
        card.addSubview(nameLabel)
        container.addSubview(card)

        return container
    }
}
