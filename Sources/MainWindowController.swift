import Cocoa
import Sparkle

final class MainWindowController: NSWindowController {
    private let updater = UpdaterManager()
    private let reporter = Reporter()

    private let statusLabel = NSTextField(labelWithString: "Hello, world!")
    private let detailLabel = NSTextField(labelWithString: "Checking for updates…")
    private let criticalBanner = NSTextField(labelWithString: "This is a critical update. Install it as soon as possible.")
    private let changelog = NSTextView()
    private lazy var updateButton = NSButton(title: "Install update", target: self, action: #selector(installUpdate))

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        window.title = "\(Config.appName) — v\(Config.version) (\(Config.platform)-\(Config.arch))"
        window.center()
        super.init(window: window)

        buildUI()
        updater.onState = { [weak self] state in
            DispatchQueue.main.async { self?.render(state) }
        }
        reporter.start()
        updater.checkForUpdates()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        statusLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        detailLabel.textColor = .secondaryLabelColor

        criticalBanner.isHidden = true
        criticalBanner.textColor = .white
        criticalBanner.drawsBackground = true
        criticalBanner.backgroundColor = .systemRed
        criticalBanner.wantsLayer = true
        criticalBanner.layer?.cornerRadius = 6
        criticalBanner.alignment = .center

        updateButton.isHidden = true
        updateButton.bezelStyle = .rounded
        updateButton.keyEquivalent = "\r"

        let checkButton = NSButton(title: "Check for Updates", target: self, action: #selector(check))
        checkButton.bezelStyle = .rounded
        let settingsButton = NSButton(title: "Settings", target: self, action: #selector(openSettings))
        settingsButton.bezelStyle = .rounded

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        changelog.isEditable = false
        changelog.drawsBackground = false
        scroll.documentView = changelog
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.heightAnchor.constraint(equalToConstant: 160).isActive = true

        let buttons = NSStackView(views: [checkButton, updateButton, settingsButton])
        buttons.orientation = .horizontal
        buttons.spacing = 12

        let stack = NSStackView(views: [statusLabel, detailLabel, criticalBanner, buttons, scroll])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = window!.contentView!
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 24),
            scroll.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -24),
        ])
    }

    private func render(_ state: UpdaterManager.State) {
        switch state {
        case .checking:
            statusLabel.stringValue = "Checking…"
            detailLabel.stringValue = "Looking for a newer version."
            criticalBanner.isHidden = true
            updateButton.isHidden = true
        case .upToDate:
            statusLabel.stringValue = "You're up to date"
            detailLabel.stringValue = "Running the latest version (v\(Config.version))."
            criticalBanner.isHidden = true
            updateButton.isHidden = true
        case .available(let item):
            let newVersion = item.displayVersionString ?? item.versionString
            statusLabel.stringValue = "Update available"
            var detail = "v\(newVersion) is available (current v\(Config.version))."
            if let interval = item.phasedRolloutInterval {
                detail += " Phased rollout: \(interval)s."
            }
            detailLabel.stringValue = detail
            criticalBanner.isHidden = !item.isCriticalUpdate
            updateButton.isHidden = false
            changelog.string = htmlToPlain(item.itemDescription) ?? "No release notes."
        case .error(let message):
            statusLabel.stringValue = "Update check failed"
            detailLabel.stringValue = message
            criticalBanner.isHidden = true
            updateButton.isHidden = true
        }
    }

    private func htmlToPlain(_ html: String?) -> String? {
        guard let html, let data = html.data(using: .utf8) else { return html }
        let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil)
        return attributed?.string ?? html
    }

    @objc private func check() { updater.checkForUpdates() }

    @objc private func installUpdate() { updater.checkForUpdates() }

    @objc private func openSettings() {
        let alert = NSAlert()
        alert.messageText = "Settings"
        alert.informativeText = "This is a Hello World example application — what did you expect to see here?"
        alert.runModal()
    }
}
