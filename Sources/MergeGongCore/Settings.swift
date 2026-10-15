import Foundation

/// User choices, in UserDefaults. Tokens live in `SecretStore`, never here.
public final class Settings {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var repos: [RepoRef] {
        get { (defaults.stringArray(forKey: "repos") ?? []).compactMap(RepoRef.init(key:)) }
        set { defaults.set(newValue.map(\.key), forKey: "repos") }
    }

    /// Only merges into this base branch ring the gong; nil means any branch.
    public var branch: String? {
        get { defaults.string(forKey: "branch") }
        set { defaults.set(newValue, forKey: "branch") }
    }

    /// Connected services; nil until the first-launch setup has run.
    public var enabledProviders: Set<ProviderKind>? {
        get { defaults.stringArray(forKey: "providers").map { Set($0.compactMap(ProviderKind.init(rawValue:))) } }
        set { defaults.set(newValue.map { $0.map(\.rawValue).sorted() }, forKey: "providers") }
    }

    /// The non-secret half of the login: the Atlassian email for Bitbucket Cloud, the server URL for Data Center.
    public func account(for kind: ProviderKind) -> String? {
        defaults.string(forKey: "account.\(kind.rawValue)")
    }

    public func setAccount(_ value: String?, for kind: ProviderKind) {
        defaults.set(value, forKey: "account.\(kind.rawValue)")
    }

    /// Upgrades settings saved by the GitHub-only version: those users skip setup and keep their repos.
    public func migrate() {
        guard enabledProviders == nil, defaults.stringArray(forKey: "repos")?.isEmpty == false else { return }
        enabledProviders = [.github]
        repos = repos
    }
}
