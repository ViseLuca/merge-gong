import AppKit
import MergeGongCore

/// The shaking GONG! panel at the top of the screen. Clicking it opens the first merged pull request.
final class GongPopup {
    private var panel: NSPanel?
    private var url: URL?

    func show(_ merges: [Merge]) {
        panel?.orderOut(nil)

        let title = label(L10n.gong, size: 54, weight: .black)
        title.textColor = NSColor(calibratedRed: 0.95, green: 0.72, blue: 0.2, alpha: 1)
        let lines = merges.prefix(3).map { m in
            label("#\(m.pr.number) \(m.pr.title)\n\(m.authorLabel) → \(m.pr.branch)", size: 15, weight: .medium)
        }
        var names: [String] = []
        for m in merges where !names.contains(m.repo.path) { names.append(m.repo.path) }
        let footer = label(names.joined(separator: " · "), size: 12, weight: .regular)
        footer.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [title] + lines + [footer])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 22, left: 28, bottom: 22, right: 28)

        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 20
        background.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            stack.topAnchor.constraint(equalTo: background.topAnchor),
            stack.bottomAnchor.constraint(equalTo: background.bottomAnchor),
            stack.widthAnchor.constraint(equalToConstant: 480),
        ])

        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = background
        panel.setContentSize(background.fittingSize)
        background.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(clicked)))
        url = merges.first?.pr.url

        if let screen = NSScreen.main?.visibleFrame {
            let size = panel.frame.size
            panel.setFrameOrigin(NSPoint(x: screen.midX - size.width / 2, y: screen.maxY - size.height - 40))
        }
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { $0.duration = 0.2; panel.animator().alphaValue = 1 }
        shake(panel)
        self.panel = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self, weak panel] in
            guard let panel, self?.panel === panel else { return }
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.5; panel.animator().alphaValue = 0 }) {
                panel.orderOut(nil)
            }
        }
    }

    @objc private func clicked() {
        if let url { NSWorkspace.shared.open(url) }
        panel?.orderOut(nil)
    }

    private func shake(_ panel: NSPanel) {
        let origin = panel.frame.origin
        for (i, dx) in [14.0, -12, 10, -8, 6, -4, 2, 0].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(i)) {
                panel.setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y))
            }
        }
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.alignment = .center
        field.preferredMaxLayoutWidth = 424
        return field
    }
}
