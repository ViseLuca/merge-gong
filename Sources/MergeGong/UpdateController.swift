import AppKit
import MergeGongCore

/// Looks for a newer GitHub release at launch and every few hours, offers it once, installs it and relaunches.
final class UpdateController {
    enum State {
        case idle
        case available(Release)
        case installing
    }

    private(set) var state = State.idle
    private let updater = Updater()
    private let worker = DispatchQueue(label: "merge-gong.update")
    private var timer: Timer?
    /// The release already offered with an alert, so periodic checks do not ask again.
    private var offered: AppVersion?

    var version: String? { updater.currentVersion?.description }

    func start() {
        guard updater.currentVersion != nil else { return }
        check(manual: false)
        timer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { [weak self] _ in
            self?.check(manual: false)
        }
    }

    /// An automatic check speaks only when there is something new; a manual one always answers.
    func check(manual: Bool) {
        if case .installing = state { return }
        let updater = updater
        worker.async { [weak self] in
            let result = Result { try updater.newerRelease() }
            DispatchQueue.main.async { self?.handle(result, manual: manual) }
        }
    }

    func install(_ release: Release) {
        guard updater.canInstall else {
            Prompt.message(L10n.cannotUpdate, info: L10n.updateByHand)
            NSWorkspace.shared.open(release.page)
            return
        }
        state = .installing
        let updater = updater
        worker.async { [weak self] in
            let result = Result { try updater.install(release) }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Self.relaunch(updater.appURL)
                case .failure(let error):
                    self?.state = .available(release)
                    if Prompt.confirm(L10n.updateFailed, info: error.localizedDescription, confirm: L10n.openReleasePage) {
                        NSWorkspace.shared.open(release.page)
                    }
                }
            }
        }
    }

    private func handle(_ result: Result<Release?, Error>, manual: Bool) {
        if case .installing = state { return }
        switch result {
        case .success(let release?):
            state = .available(release)
            // Never stack an alert on top of the setup dialogs; the menu still shows the update.
            guard manual || (offered != release.version && NSApp.modalWindow == nil) else { return }
            offered = release.version
            if Prompt.confirm(L10n.updateAvailable(release.version.description),
                              info: L10n.updateInfo(current: version ?? "?"), confirm: L10n.updateNow) {
                install(release)
            }
        case .success(nil):
            state = .idle
            if manual { Prompt.message(L10n.upToDate, info: L10n.upToDateInfo(version ?? "?")) }
        case .failure(let error):
            if manual { Prompt.message(L10n.updateCheckFailed, info: error.localizedDescription) }
        }
    }

    /// Quits, and reopens the new copy once this process is gone.
    private static func relaunch(_ app: URL) {
        let reopen = Process()
        reopen.executableURL = URL(fileURLWithPath: "/bin/sh")
        reopen.arguments = ["-c", #"while kill -0 "$1" 2>/dev/null; do sleep 0.2; done; open "$2""#,
                            "sh", String(ProcessInfo.processInfo.processIdentifier), app.path]
        if (try? reopen.run()) == nil {
            Prompt.message(L10n.updateInstalled, info: L10n.reopenByHand)
        }
        NSApp.terminate(nil)
    }
}
