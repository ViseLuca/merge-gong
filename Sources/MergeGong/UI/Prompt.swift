import AppKit
import MergeGongCore

/// Small modal dialogs. A menu bar app has no window, so each one brings the app to the front first.
enum Prompt {
    static func text(_ message: String, hint: String, current: String?) -> String? {
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.placeholderString = hint
        field.stringValue = current ?? ""
        let alert = makeAlert(message, buttons: [L10n.ok, L10n.cancel])
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue.trimmingCharacters(in: .whitespaces)
    }

    /// Asks for a repo, with a service picker when more than one is connected.
    static func repo(providers: [ProviderKind]) -> RepoRef? {
        guard let first = providers.first else { return nil }
        let picker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 260, height: 26), pullsDown: false)
        picker.addItems(withTitles: providers.map(\.displayName))
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.placeholderString = first.repoHint
        let update = Handler { field.placeholderString = providers[picker.indexOfSelectedItem].repoHint }
        picker.target = update
        picker.action = #selector(Handler.fire)

        let alert = makeAlert(L10n.addRepoPrompt, buttons: [L10n.ok, L10n.cancel])
        alert.accessoryView = stack(providers.count > 1 ? [picker, field] : [field])
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let path = field.stringValue.trimmingCharacters(in: .whitespaces)
        guard RepoRef.isValidPath(path) else { return nil }
        return RepoRef(provider: providers[picker.indexOfSelectedItem], path: path)
    }

    static func message(_ title: String, info: String) {
        makeAlert(title, info: info, buttons: [L10n.ok]).runModal()
    }

    /// True when the user picks `confirm` rather than cancel.
    static func confirm(_ title: String, info: String, confirm: String) -> Bool {
        makeAlert(title, info: info, buttons: [confirm, L10n.cancel]).runModal() == .alertFirstButtonReturn
    }

    static func makeAlert(_ title: String, info: String = "", buttons: [String]) -> NSAlert {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        for button in buttons { alert.addButton(withTitle: button) }
        return alert
    }

    /// A vertical stack sized to fit, as alert accessory views need a frame.
    static func stack(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.frame = NSRect(origin: .zero, size: stack.fittingSize)
        return stack
    }
}

/// Lets a closure be the target of a control or menu item. Targets are weak, so the owner must retain it
/// (menu items keep theirs in `representedObject`).
final class Handler: NSObject {
    private let block: () -> Void

    init(_ block: @escaping () -> Void) {
        self.block = block
    }

    @objc func fire() { block() }
}
