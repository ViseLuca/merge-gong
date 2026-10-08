import AppKit
import AVFoundation

// MARK: - GitHub via `gh`

struct PullRequest: Decodable {
    struct User: Decodable { let login: String }
    struct Base: Decodable { let ref: String }

    let number: Int
    let title: String
    let merged_at: String?
    let html_url: String
    let user: User
    let base: Base
}

struct Repo: Decodable { let full_name: String }

struct Merge {
    let repo: String
    let pr: PullRequest
}

enum GH {
    static let path: String? = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }

    static func api(_ endpoint: String) throws -> Data {
        guard let path else {
            throw err("gh non trovato. Installa con: brew install gh")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["api", endpoint]
        let out = Pipe(), errPipe = Pipe()
        process.standardOutput = out
        process.standardError = errPipe
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw err(String(decoding: errData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return data
    }

    static func merges(repo: String) throws -> [PullRequest] {
        let data = try api("repos/\(repo)/pulls?state=closed&sort=updated&direction=desc&per_page=30")
        return try JSONDecoder().decode([PullRequest].self, from: data).filter { $0.merged_at != nil }
    }

    static func repos() throws -> [String] {
        let data = try api("user/repos?per_page=30&sort=pushed&affiliation=owner,collaborator,organization_member")
        return try JSONDecoder().decode([Repo].self, from: data).map(\.full_name)
    }

    private static func err(_ msg: String) -> NSError {
        NSError(domain: "gh", code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}

// MARK: - Gong synth

final class Gong {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffer: AVAudioPCMBuffer

    init() {
        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let frames = AVAudioFrameCount(sampleRate * 7)
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames

        // (frequency ratio, amplitude, seconds to fade out): inharmonic, like a real gong
        let partials: [(Double, Double, Double)] = [
            (1.00, 1.00, 6.5), (1.52, 0.60, 5.0), (2.03, 0.50, 4.5), (2.61, 0.35, 4.0),
            (3.17, 0.30, 3.2), (3.90, 0.20, 2.6), (4.70, 0.15, 2.0), (5.60, 0.10, 1.5),
        ]
        let base = 92.0
        var phases = [Double](repeating: 0, count: partials.count)
        var samples = [Float](repeating: 0, count: Int(frames))
        var noiseState = 0.0
        var peak: Float = 0

        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let glide = 1 + 0.03 * exp(-t * 5)
            var value = 0.0
            for (k, (ratio, amp, fade)) in partials.enumerated() {
                phases[k] += 2 * .pi * base * ratio * glide / sampleRate
                let envelope = amp * (1 - exp(-t * 30)) * exp(-t * 4.6 / fade)
                let shimmer = 0.7 + 0.3 * cos(2 * .pi * (0.6 + Double(k) * 0.35) * t)
                value += envelope * shimmer * sin(phases[k])
            }
            if t < 0.25 {
                noiseState += (Double.random(in: -1...1) - noiseState) * 0.25
                value += noiseState * 1.5 * pow(1 - t / 0.25, 3)
            }
            samples[i] = Float(value)
            peak = max(peak, abs(Float(value)))
        }

        let left = buffer.floatChannelData![0], right = buffer.floatChannelData![1]
        for i in 0..<Int(frames) {
            left[i] = samples[i] / peak * 0.9
            right[i] = left[i]
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play() {
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }
}

// MARK: - Popup

final class GongPopup {
    private var panel: NSPanel?
    private var url: URL?

    func show(_ merges: [Merge]) {
        panel?.orderOut(nil)

        let title = label("GONG!", size: 54, weight: .black)
        title.textColor = NSColor(calibratedRed: 0.95, green: 0.72, blue: 0.2, alpha: 1)
        let lines = merges.prefix(3).map { m in
            label("#\(m.pr.number) \(m.pr.title)\n@\(m.pr.user.login) → \(m.pr.base.ref)", size: 15, weight: .medium)
        }
        var names: [String] = []
        for m in merges where !names.contains(m.repo) { names.append(m.repo) }
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
        url = merges.first.flatMap { URL(string: $0.pr.html_url) }

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

// MARK: - Menu bar app

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let gong = Gong()
    private let popup = GongPopup()
    private let worker = DispatchQueue(label: "merge-gong.gh")
    private let pollSeconds = 30.0

    private var seen: [String: Set<Int>] = [:]
    private var primed = Set<String>()
    private var recent: [Merge] = []
    private var knownRepos: [String] = []
    private var errors: [String: String] = [:]
    private var timer: Timer?
    private var generation = 0

    private var repos: [String] {
        get { UserDefaults.standard.stringArray(forKey: "repos") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "repos") }
    }

    private var branch: String? {
        get { UserDefaults.standard.string(forKey: "branch") }
        set { UserDefaults.standard.set(newValue, forKey: "branch") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.title = "🔔"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        loadRepos()
        restart()
    }

    // MARK: Polling

    private func restart() {
        generation += 1
        seen = [:]
        primed = []
        recent = []
        errors = [:]
        timer?.invalidate()
        guard !repos.isEmpty else { return }
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: pollSeconds, repeats: true) { [weak self] _ in self?.poll() }
    }

    private func poll() {
        let repos = repos, branch = branch, generation = generation
        worker.async { [weak self] in
            let results = repos.map { repo in (repo, Result { try GH.merges(repo: repo) }) }
            DispatchQueue.main.async {
                guard let self, self.generation == generation else { return }
                var fresh: [Merge] = []
                for (repo, result) in results {
                    switch result {
                    case .success(let prs):
                        self.errors[repo] = nil
                        fresh += self.handle(prs.filter { branch == nil || $0.base.ref == branch }, repo: repo)
                    case .failure(let error):
                        self.errors[repo] = error.localizedDescription
                    }
                }
                if !fresh.isEmpty { self.celebrate(fresh) }
            }
        }
    }

    /// Records the repo's merges and returns the new ones (none on the first poll, which only primes `seen`).
    private func handle(_ prs: [PullRequest], repo: String) -> [Merge] {
        let fresh = prs.filter { !seen[repo, default: []].contains($0.number) }
        seen[repo, default: []].formUnion(prs.map(\.number))
        recent = (recent.filter { $0.repo != repo } + prs.map { Merge(repo: repo, pr: $0) })
            .sorted { ($0.pr.merged_at ?? "") > ($1.pr.merged_at ?? "") }
            .prefix(8).map { $0 }
        let isPrimed = primed.contains(repo)
        primed.insert(repo)
        return isPrimed ? fresh.map { Merge(repo: repo, pr: $0) } : []
    }

    private func celebrate(_ merges: [Merge]) {
        gong.play()
        popup.show(merges)
        statusItem.button?.title = "🔔 GONG!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.statusItem.button?.title = "🔔"
        }
    }

    private func loadRepos() {
        worker.async { [weak self] in
            let list = (try? GH.repos()) ?? []
            DispatchQueue.main.async { self?.knownRepos = list }
        }
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let watched = repos
        menu.addItem(info(watched.isEmpty ? "Nessun repo scelto" : "In ascolto su \(watched.count) repo"))
        for name in watched { menu.addItem(info("  \(name)")) }
        menu.addItem(info("Branch: \(branch ?? "tutti")"))
        for name in watched {
            if let error = errors[name] { menu.addItem(info("⚠️ \(name): \(error.prefix(80))")) }
        }

        if !recent.isEmpty {
            menu.addItem(.separator())
            menu.addItem(info("Ultimi merge"))
            for m in recent {
                let repoName = watched.count > 1 ? "\(m.repo.split(separator: "/").last ?? "") " : ""
                let item = NSMenuItem(title: "\(repoName)#\(m.pr.number) \(m.pr.title.prefix(50)) — @\(m.pr.user.login)", action: #selector(openPR(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = m.pr.html_url
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let repoMenu = NSMenu()
        for name in watched + knownRepos.filter({ !watched.contains($0) }) {
            let item = NSMenuItem(title: name, action: #selector(toggleRepo(_:)), keyEquivalent: "")
            item.target = self
            item.state = watched.contains(name) ? .on : .off
            repoMenu.addItem(item)
        }
        repoMenu.addItem(.separator())
        repoMenu.addItem(action("Aggiungi altro repo…", #selector(askRepo)))
        let repoItem = NSMenuItem(title: "Repo da ascoltare", action: nil, keyEquivalent: "")
        repoItem.submenu = repoMenu
        menu.addItem(repoItem)
        menu.addItem(action("Filtra branch…", #selector(askBranch)))
        menu.addItem(action("Suona il gong", #selector(testGong), key: "g"))
        menu.addItem(.separator())
        menu.addItem(action("Esci", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp))
    }

    private func info(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func action(_ title: String, _ selector: Selector, key: String = "", target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.target = target ?? self
        return item
    }

    @objc private func openPR(_ sender: NSMenuItem) {
        if let link = sender.representedObject as? String, let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleRepo(_ sender: NSMenuItem) {
        if repos.contains(sender.title) {
            repos.removeAll { $0 == sender.title }
        } else {
            repos.append(sender.title)
        }
        restart()
    }

    @objc private func askRepo() {
        guard let value = prompt("Repo da aggiungere", hint: "owner/nome", current: nil) else { return }
        guard value.range(of: #"^[\w.-]+/[\w.-]+$"#, options: .regularExpression) != nil,
              !repos.contains(value) else { return }
        repos.append(value)
        restart()
    }

    @objc private func askBranch() {
        guard let value = prompt("Suona solo per merge su questo branch (vuoto = tutti)", hint: "env/prod", current: branch) else { return }
        branch = value.isEmpty ? nil : value
        restart()
    }

    @objc private func testGong() {
        gong.play()
        let fake = PullRequest(number: 0, title: "Prova del gong", merged_at: nil, html_url: "https://github.com",
                               user: .init(login: NSUserName()), base: .init(ref: branch ?? "main"))
        popup.show([Merge(repo: repos.first ?? "nessun repo", pr: fake)])
    }

    private func prompt(_ message: String, hint: String, current: String?) -> String? {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Annulla")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.placeholderString = hint
        field.stringValue = current ?? ""
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue.trimmingCharacters(in: .whitespaces)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
