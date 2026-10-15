import Foundation

/// GitHub through the `gh` CLI, so it sees exactly what the user's `gh` login sees and stores no token.
public struct GitHubProvider: Provider {
    public let kind = ProviderKind.github

    public init() {}

    public func merges(repo path: String) throws -> [PullRequest] {
        try Self.decodeMerges(api("repos/\(path)/pulls?state=closed&sort=updated&direction=desc&per_page=30"))
    }

    public func repos() throws -> [String] {
        try Self.decodeRepos(api("user/repos?per_page=30&sort=pushed&affiliation=owner,collaborator,organization_member"))
    }

    private func api(_ endpoint: String) throws -> Data {
        guard let gh = ProcessRunner.find("gh") else {
            throw MergeGongError("gh non trovato. Installa con: brew install gh")
        }
        return try ProcessRunner.run(gh, ["api", endpoint])
    }

    private struct Pull: Decodable {
        struct User: Decodable { let login: String }
        struct Base: Decodable { let ref: String }

        let number: Int
        let title: String
        let mergedAt: Date?
        let htmlUrl: URL
        let user: User
        let base: Base
    }

    private struct Repo: Decodable { let fullName: String }

    /// Closed pull requests, keeping only the merged ones.
    static func decodeMerges(_ data: Data) throws -> [PullRequest] {
        try JSONDecoder.api().decode([Pull].self, from: data).compactMap { pull in
            pull.mergedAt.map {
                PullRequest(number: pull.number, title: pull.title, author: pull.user.login,
                            branch: pull.base.ref, url: pull.htmlUrl, mergedAt: $0)
            }
        }
    }

    static func decodeRepos(_ data: Data) throws -> [String] {
        try JSONDecoder.api().decode([Repo].self, from: data).map(\.fullName)
    }
}
