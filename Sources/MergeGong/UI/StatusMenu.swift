import AppKit
import MergeGongCore

protocol StatusMenuActions: AnyObject {
    func toggle(_ repo: RepoRef)
    func addRepo()
    func editBranch()
    func connect(_ kind: ProviderKind)
    func disconnect(_ kind: ProviderKind)
    func testGong()
}

/// What the menu shows, read each time it opens.
struct MenuState {
    var watched: [RepoRef]
    var knownRepos: [ProviderKind: [String]]
    var enabled: Set<ProviderKind>
    var branch: String?
    var repoErrors: [RepoRef: String]
    var providerErrors: [ProviderKind: String]
    var recent: [Merge]
}

/// The 🔔 menu, rebuilt every time it opens.
final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    weak var actions: StatusMenuActions?
    var state: () -> MenuState

    init(state: @escaping () -> MenuState) {
        self.state = state
        super.init()
        menu.delegate = self
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let state = state()
        let enabled = ProviderKind.allCases.filter(state.enabled.contains)
        let mixed = Set(state.watched.map(\.provider)).count > 1
        menu.removeAllItems()

        menu.addItem(info(state.watched.isEmpty ? L10n.noRepos : L10n.listening(state.watched.count)))
        for repo in state.watched { menu.addItem(info("  \(label(repo, tagged: mixed))")) }
        menu.addItem(info(L10n.branch(state.branch)))
        for kind in enabled {
            if let error = state.providerErrors[kind] { menu.addItem(info("⚠️ \(kind.displayName): \(error.prefix(80))")) }
        }
        for repo in state.watched {
            if let error = state.repoErrors[repo] { menu.addItem(info("⚠️ \(repo.path): \(error.prefix(80))")) }
        }

        if !state.recent.isEmpty {
            menu.addItem(.separator())
            menu.addItem(info(L10n.recentMerges))
            for merge in state.recent {
                let repoName = state.watched.count > 1 ? "\(merge.repo.name) " : ""
                menu.addItem(action("\(repoName)#\(merge.pr.number) \(merge.pr.title.prefix(50)) — \(merge.authorLabel)") {
                    if let url = merge.pr.url { NSWorkspace.shared.open(url) }
                })
            }
        }

        menu.addItem(.separator())
        menu.addItem(submenu(L10n.reposMenu, reposMenu(state, enabled: enabled)))
        menu.addItem(submenu(L10n.services, servicesMenu(state)))
        menu.addItem(action(L10n.filterBranch) { [weak self] in self?.actions?.editBranch() })
        menu.addItem(action(L10n.strike, key: "g") { [weak self] in self?.actions?.testGong() })
        menu.addItem(.separator())
        let quit = NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    /// Watched repos first, then the account's recent ones, grouped by service when several are connected.
    private func reposMenu(_ state: MenuState, enabled: [ProviderKind]) -> NSMenu {
        let menu = NSMenu()
        guard !enabled.isEmpty else {
            menu.addItem(info(L10n.noServices))
            return menu
        }
        for kind in enabled {
            if enabled.count > 1 { menu.addItem(info(kind.displayName)) }
            let watched = state.watched.filter { $0.provider == kind }
            let known = (state.knownRepos[kind] ?? []).map { RepoRef(provider: kind, path: $0) }
            for repo in watched + known.filter({ !watched.contains($0) }) {
                let item = action(repo.path) { [weak self] in self?.actions?.toggle(repo) }
                item.state = watched.contains(repo) ? .on : .off
                menu.addItem(item)
            }
        }
        menu.addItem(.separator())
        menu.addItem(action(L10n.addRepo) { [weak self] in self?.actions?.addRepo() })
        return menu
    }

    private func servicesMenu(_ state: MenuState) -> NSMenu {
        let menu = NSMenu()
        for kind in ProviderKind.allCases {
            let options = NSMenu()
            if state.enabled.contains(kind) {
                options.addItem(info(state.providerErrors[kind].map { "⚠️ \($0.prefix(80))" } ?? L10n.connected))
                if kind != .github {
                    options.addItem(action(L10n.configure) { [weak self] in self?.actions?.connect(kind) })
                }
                options.addItem(action(L10n.disconnect) { [weak self] in self?.actions?.disconnect(kind) })
            } else {
                options.addItem(action(L10n.connect) { [weak self] in self?.actions?.connect(kind) })
            }
            let item = submenu(kind.displayName, options)
            item.state = state.enabled.contains(kind) ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func label(_ repo: RepoRef, tagged: Bool) -> String {
        tagged ? "[\(repo.provider.shortName)] \(repo.path)" : repo.path
    }

    private func info(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func action(_ title: String, key: String = "", _ block: @escaping () -> Void) -> NSMenuItem {
        let handler = Handler(block)
        let item = NSMenuItem(title: title, action: #selector(Handler.fire), keyEquivalent: key)
        item.target = handler
        item.representedObject = handler
        return item
    }

    private func submenu(_ title: String, _ submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }
}
