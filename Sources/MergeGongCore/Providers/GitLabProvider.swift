import Foundation

/// gitlab.com or a self-managed GitLab, REST API v4, authenticated with a personal access token.
public struct GitLabProvider: Provider {
    public let kind = ProviderKind.gitlab
    private let client: HTTPClient

    public init(baseURL: URL, token: String) {
        client = HTTPClient(baseURL: baseURL, authorization: HTTPClient.bearer(token))
    }

    public func merges(repo path: String) throws -> [PullRequest] {
        try Self.decodeMerges(client.get(
            "api/v4/projects/\(Self.projectID(path))/merge_requests?state=merged&order_by=updated_at&sort=desc&per_page=30"))
    }

    public func repos() throws -> [String] {
        try Self.decodeRepos(client.get("api/v4/projects?membership=true&simple=true&order_by=last_activity_at&sort=desc&per_page=30"))
    }

    /// A project path used as its id, with the group slashes encoded (`group%2Fsub%2Fproject`).
    static func projectID(_ path: String) -> String {
        path.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._"))) ?? path
    }

    private struct MergeRequest: Decodable {
        struct Author: Decodable { let username: String }

        let iid: Int
        let title: String
        let author: Author
        let targetBranch: String
        let webUrl: URL
        /// Missing on merge requests merged by very old GitLab versions.
        let mergedAt: Date?
        let updatedAt: Date
    }

    private struct Project: Decodable { let pathWithNamespace: String }

    /// Numbered by `iid`, the `!42` shown in the project, not the instance-wide `id`.
    static func decodeMerges(_ data: Data) throws -> [PullRequest] {
        try JSONDecoder.api().decode([MergeRequest].self, from: data).map { mr in
            PullRequest(number: mr.iid, title: mr.title, author: mr.author.username,
                        branch: mr.targetBranch, url: mr.webUrl, mergedAt: mr.mergedAt ?? mr.updatedAt)
        }
    }

    static func decodeRepos(_ data: Data) throws -> [String] {
        try JSONDecoder.api().decode([Project].self, from: data).map(\.pathWithNamespace)
    }
}
