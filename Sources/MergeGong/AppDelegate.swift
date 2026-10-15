import AppKit
import MergeGongCore

/// Wires settings, services, polling and UI together.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settings = Settings()
    private let secrets = SecretStore()
    private let gong = Gong()
    private let popup = GongPopup()
    private let poller = Poller()
    private let updates = UpdateController()
    private let worker = DispatchQueue(label: "merge-gong.connect")
    private lazy var statusMenu = StatusMenu { [unowned self] in menuState }

    private var providers: [ProviderKind: Provider] = [:]
    private var tracker = MergeTracker()
    private var knownRepos: [ProviderKind: [String]] = [:]
    private var repoErrors: [RepoRef: String] = [:]
    private var providerErrors: [ProviderKind: String] = [:]
    /// Bumped on every `connect()` so a slower, older connection cannot overwrite a newer one.
    private var connection = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.title = "🔔"
        statusMenu.actions = self
        statusItem.menu = statusMenu.menu
        poller.onResults = { [weak self] in self?.handle($0) }

        settings.migrate()
        if settings.enabledProviders == nil {
            runSetup()
        } else {
            connect()
        }
        updates.start()
    }

    private var enabled: Set<ProviderKind> {
        settings.enabledProviders ?? []
    }

    private var menuState: MenuState {
        MenuState(watched: settings.repos, knownRepos: knownRepos, enabled: enabled, branch: settings.branch,
                  repoErrors: repoErrors, providerErrors: providerErrors, recent: tracker.recent,
                  version: updates.version, update: updates.state)
    }

    // MARK: Connecting

    private func runSetup() {
        let chosen = SetupFlow.chooseServices(current: [.github]) ?? []
        settings.enabledProviders = []
        var verify = Set<ProviderKind>()
        for kind in ProviderKind.allCases where chosen.contains(kind) {
            if kind == .github || askCredentials(kind) {
                settings.enabledProviders = enabled.union([kind])
                verify.insert(kind)
            }
        }
        connect(verifying: verify)
    }

    /// Shows the credentials form and saves what it gets. False if cancelled or not saved.
    private func askCredentials(_ kind: ProviderKind) -> Bool {
        guard let credentials = SetupFlow.askCredentials(for: kind, account: settings.account(for: kind),
                                                         hasToken: secrets.hasToken(for: kind)) else { return false }
        do {
            if !credentials.token.isEmpty { try secrets.save(credentials.token, for: kind) }
            settings.setAccount(credentials.account, for: kind)
            return true
        } catch {
            Prompt.message(L10n.connectionFailed(kind), info: error.localizedDescription)
            return false
        }
    }

    /// Builds the enabled services (reading tokens may hit the Keychain or 1Password), restarts polling and
    /// loads each account's repos. A service in `verifying` that fails gets an alert instead of only a ⚠️.
    private func connect(verifying: Set<ProviderKind> = []) {
        connection += 1
        let connection = connection, enabled = enabled, settings = settings, secrets = secrets
        worker.async { [weak self] in
            var built: [ProviderKind: Provider] = [:], failures: [ProviderKind: String] = [:]
            for kind in enabled {
                do { built[kind] = try ProviderFactory.make(kind, settings: settings, secrets: secrets) }
                catch { failures[kind] = error.localizedDescription }
            }
            DispatchQueue.main.async {
                guard let self, self.connection == connection else { return }
                self.providers = built
                self.providerErrors = failures
                self.knownRepos = [:]
                self.restartPolling()
                for kind in failures.keys where verifying.contains(kind) { self.reportFailure(kind) }
                self.loadRepos(verifying: verifying.subtracting(failures.keys))
            }
        }
    }

    /// Fetches each account's recent repos for the menu. Doubles as the connection test after setup.
    private func loadRepos(verifying: Set<ProviderKind>) {
        let providers = providers, connection = connection
        worker.async { [weak self] in
            let results = providers.map { kind, provider in (kind, Result { try provider.repos() }) }
            DispatchQueue.main.async {
                guard let self, self.connection == connection else { return }
                for (kind, result) in results {
                    switch result {
                    case .success(let repos):
                        self.knownRepos[kind] = repos
                    case .failure(let error):
                        self.providerErrors[kind] = error.localizedDescription
                        if verifying.contains(kind) { self.reportFailure(kind) }
                    }
                }
            }
        }
    }

    /// Alerts that `kind` could not connect; for token-based services, offers to fix the credentials.
    private func reportFailure(_ kind: ProviderKind) {
        let message = providerErrors[kind] ?? ""
        guard kind != .github else { return Prompt.message(L10n.connectionFailed(kind), info: message) }
        if Prompt.confirm(L10n.connectionFailed(kind), info: message, confirm: L10n.retry) {
            connect(kind)
        }
    }

    // MARK: Polling

    private func restartPolling() {
        tracker = MergeTracker()
        repoErrors = [:]
        poller.start(settings.repos.compactMap { repo in providers[repo.provider].map { (repo, $0) } })
    }

    private func handle(_ results: Poller.Results) {
        let branch = settings.branch
        var fresh: [Merge] = []
        for (repo, result) in results {
            switch result {
            case .success(let prs):
                repoErrors[repo] = nil
                fresh += tracker.record(prs.filter { branch == nil || $0.branch == branch }, repo: repo)
            case .failure(let error):
                repoErrors[repo] = error.localizedDescription
            }
        }
        if !fresh.isEmpty { celebrate(fresh) }
    }

    private func celebrate(_ merges: [Merge]) {
        gong.play()
        popup.show(merges)
        statusItem.button?.title = "🔔 GONG!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.statusItem.button?.title = "🔔"
        }
    }
}

// MARK: - Menu actions

extension AppDelegate: StatusMenuActions {
    func toggle(_ repo: RepoRef) {
        if settings.repos.contains(repo) {
            settings.repos.removeAll { $0 == repo }
        } else {
            settings.repos.append(repo)
        }
        restartPolling()
    }

    func addRepo() {
        guard let repo = Prompt.repo(providers: ProviderKind.allCases.filter(enabled.contains)),
              !settings.repos.contains(repo) else { return }
        settings.repos.append(repo)
        restartPolling()
    }

    func editBranch() {
        guard let value = Prompt.text(L10n.branchPrompt, hint: L10n.branchHint, current: settings.branch) else { return }
        settings.branch = value.isEmpty ? nil : value
        restartPolling()
    }

    func connect(_ kind: ProviderKind) {
        guard kind == .github || askCredentials(kind) else { return }
        settings.enabledProviders = enabled.union([kind])
        connect(verifying: [kind])
    }

    func disconnect(_ kind: ProviderKind) {
        guard Prompt.confirm(L10n.disconnectTitle(kind), info: L10n.disconnectInfo, confirm: L10n.disconnect) else { return }
        try? secrets.remove(for: kind)
        settings.setAccount(nil, for: kind)
        settings.enabledProviders = enabled.subtracting([kind])
        settings.repos.removeAll { $0.provider == kind }
        connect()
    }

    func testGong() {
        gong.play()
        let fake = PullRequest(number: 0, title: L10n.testTitle, author: NSUserName(),
                               branch: settings.branch ?? "main", url: nil, mergedAt: Date())
        popup.show([Merge(repo: settings.repos.first ?? RepoRef(provider: .github, path: L10n.noRepo), pr: fake)])
    }

    func checkForUpdates() {
        updates.check(manual: true)
    }

    func installUpdate() {
        if case .available(let release) = updates.state { updates.install(release) }
    }
}
