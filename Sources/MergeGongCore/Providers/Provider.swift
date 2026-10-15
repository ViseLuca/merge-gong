import Foundation

/// A service hosting repos whose merges Merge Gong watches. Calls block: run them off the main thread.
public protocol Provider {
    var kind: ProviderKind { get }
    /// Recently merged pull requests of the repo at `path`.
    func merges(repo path: String) throws -> [PullRequest]
    /// Paths of the repos the account works on, most recently active first.
    func repos() throws -> [String]
}

public enum ProviderFactory {
    /// Builds the client for `kind` from the saved settings. Reading the token may hit the Keychain or 1Password.
    public static func make(_ kind: ProviderKind, settings: Settings, secrets: SecretStore) throws -> Provider {
        switch kind {
        case .github:
            return GitHubProvider()
        case .bitbucketCloud:
            guard let email = settings.account(for: kind), let token = try secrets.token(for: kind) else {
                throw MergeGongError("\(kind.displayName) non configurato")
            }
            return BitbucketCloudProvider(email: email, token: token)
        case .bitbucketServer:
            guard let address = settings.account(for: kind), let token = try secrets.token(for: kind) else {
                throw MergeGongError("\(kind.displayName) non configurato")
            }
            guard let baseURL = BitbucketServerProvider.baseURL(from: address) else {
                throw MergeGongError("URL del server non valido: \(address)")
            }
            return BitbucketServerProvider(baseURL: baseURL, token: token)
        }
    }
}
