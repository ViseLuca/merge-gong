import Foundation

/// bitbucket.org REST API 2.0, authenticated with an Atlassian account email and API token.
public struct BitbucketCloudProvider: Provider {
    public let kind = ProviderKind.bitbucketCloud
    private let client: HTTPClient

    public init(email: String, token: String) {
        client = HTTPClient(baseURL: URL(string: "https://api.bitbucket.org/2.0/")!,
                            authorization: HTTPClient.basic(user: email, password: token))
    }

    public func merges(repo path: String) throws -> [PullRequest] {
        try Self.decodeMerges(client.get("repositories/\(path)/pullrequests?state=MERGED&sort=-updated_on&pagelen=30"))
    }

    /// The most recently updated repos across all the user's workspaces.
    public func repos() throws -> [String] {
        // `workspaces` is the older endpoint Atlassian is phasing out; it is only the fallback.
        let page = try (try? client.get("user/workspaces?pagelen=50")) ?? client.get("workspaces?pagelen=50")
        let workspaces = try Self.decodeWorkspaces(page)
        var repos: [(name: String, updated: Date)] = []
        for workspace in workspaces {
            repos += try Self.decodeRepos(client.get("repositories/\(workspace)?sort=-updated_on&pagelen=30"))
        }
        return repos.sorted { $0.updated > $1.updated }.prefix(30).map(\.name)
    }

    private struct Pull: Decodable {
        struct Author: Decodable { let displayName: String }
        struct Destination: Decodable {
            struct Branch: Decodable { let name: String }
            let branch: Branch
        }
        struct Links: Decodable {
            struct Link: Decodable { let href: URL }
            let html: Link
        }

        let id: Int
        let title: String
        let author: Author?
        let destination: Destination
        let links: Links
        let updatedOn: Date
    }

    /// `user/workspaces` nests the workspace in `workspace`; the older `workspaces` endpoint does not.
    private struct WorkspaceEntry: Decodable {
        struct Workspace: Decodable { let slug: String }
        let slug: String?
        let workspace: Workspace?
    }

    private struct Repo: Decodable {
        let fullName: String
        let updatedOn: Date
    }

    /// A merged pull request's last update is its merge, as merged ones can no longer change.
    static func decodeMerges(_ data: Data) throws -> [PullRequest] {
        try JSONDecoder.api().decode(Page<Pull>.self, from: data).values.map { pull in
            PullRequest(number: pull.id, title: pull.title, author: pull.author?.displayName ?? "?",
                        branch: pull.destination.branch.name, url: pull.links.html.href, mergedAt: pull.updatedOn)
        }
    }

    static func decodeWorkspaces(_ data: Data) throws -> [String] {
        try JSONDecoder.api().decode(Page<WorkspaceEntry>.self, from: data).values.compactMap { $0.workspace?.slug ?? $0.slug }
    }

    static func decodeRepos(_ data: Data) throws -> [(name: String, updated: Date)] {
        try JSONDecoder.api().decode(Page<Repo>.self, from: data).values.map { ($0.fullName, $0.updatedOn) }
    }
}
