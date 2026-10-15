import AppKit
import MergeGongCore

/// What the user typed to connect a Bitbucket service. An empty token means "keep the saved one".
struct Credentials {
    let account: String
    let token: String
}

/// The dialogs to pick services and connect them.
enum SetupFlow {
    /// Checkboxes for each service; nil if cancelled.
    static func chooseServices(current: Set<ProviderKind>) -> Set<ProviderKind>? {
        let boxes = ProviderKind.allCases.map { kind in
            let box = NSButton(checkboxWithTitle: kind.displayName, target: nil, action: nil)
            box.state = current.contains(kind) ? .on : .off
            return box
        }
        let alert = Prompt.makeAlert(L10n.setupTitle, info: L10n.setupInfo, buttons: [L10n.ok, L10n.cancel])
        alert.accessoryView = Prompt.stack(boxes)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return Set(zip(ProviderKind.allCases, boxes).filter { $0.1.state == .on }.map(\.0))
    }

    /// Account and token form for a Bitbucket service; nil if cancelled. Asks again while a field is missing.
    static func askCredentials(for kind: ProviderKind, account: String?, hasToken: Bool) -> Credentials? {
        let accountField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        accountField.placeholderString = kind.accountHint
        accountField.stringValue = account ?? ""
        let tokenField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        tokenField.placeholderString = hasToken ? L10n.tokenKeep : L10n.tokenHint

        let grid = NSGridView(views: [
            [NSTextField(labelWithString: kind.accountLabel), accountField],
            [NSTextField(labelWithString: kind.tokenLabel), tokenField],
        ])
        grid.rowSpacing = 8
        grid.column(at: 0).xPlacement = .trailing
        grid.frame = NSRect(origin: .zero, size: grid.fittingSize)

        let alert = Prompt.makeAlert(L10n.connectTitle(kind), info: kind.setupHelp, buttons: [L10n.ok, L10n.cancel])
        alert.accessoryView = grid
        alert.window.initialFirstResponder = accountField
        while alert.runModal() == .alertFirstButtonReturn {
            let account = accountField.stringValue.trimmingCharacters(in: .whitespaces)
            let token = tokenField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !account.isEmpty, !token.isEmpty || hasToken {
                return Credentials(account: account, token: token)
            }
            alert.informativeText = "\(L10n.missingFields)\n\n\(kind.setupHelp)"
        }
        return nil
    }
}
