import Foundation

public enum ProviderKind: String, CaseIterable {
    case github
    case bitbucketCloud = "bitbucket"
    case bitbucketServer = "bitbucket-dc"

    public var displayName: String {
        switch self {
        case .github: "GitHub"
        case .bitbucketCloud: "Bitbucket Cloud"
        case .bitbucketServer: "Bitbucket Data Center"
        }
    }

    public var shortName: String {
        switch self {
        case .github: "GH"
        case .bitbucketCloud: "BB"
        case .bitbucketServer: "BB DC"
        }
    }

    /// Bitbucket Cloud allows 1,000 requests per hour, so it is polled half as often as the others.
    public var pollInterval: TimeInterval {
        self == .bitbucketCloud ? 60 : 30
    }
}

/// A repo on a given service. `path` is `owner/name` on GitHub, `workspace/slug` on Bitbucket Cloud
/// and `PROJECT/slug` on Bitbucket Data Center.
public struct RepoRef: Hashable {
    public let provider: ProviderKind
    public let path: String

    public init(provider: ProviderKind, path: String) {
        self.provider = provider
        self.path = path
    }

    /// Parses a saved key such as `bitbucket:workspace/slug`. Keys saved before Bitbucket support
    /// have no prefix and are GitHub repos.
    public init?(key: String) {
        let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
        switch parts.count {
        case 1: self.init(provider: .github, path: parts[0])
        case 2:
            guard let provider = ProviderKind(rawValue: parts[0]) else { return nil }
            self.init(provider: provider, path: parts[1])
        default: return nil
        }
        guard Self.isValidPath(path) else { return nil }
    }

    public var key: String { "\(provider.rawValue):\(path)" }

    /// The repo name without its owner.
    public var name: String { String(path.split(separator: "/").last ?? "") }

    /// `owner/name`; Data Center personal projects start with `~`.
    public static func isValidPath(_ path: String) -> Bool {
        path.range(of: #"^~?[\w.-]+/[\w.-]+$"#, options: .regularExpression) != nil
    }
}
