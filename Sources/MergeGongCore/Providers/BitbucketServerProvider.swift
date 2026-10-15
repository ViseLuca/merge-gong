import Foundation

/// Self-hosted Bitbucket Data Center (or Server), REST API 1.0, authenticated with an HTTP access token.
public struct BitbucketServerProvider: Provider {
    public let kind = ProviderKind.bitbucketServer
    private let client: HTTPClient

    public init(baseURL: URL, token: String) {
        client = HTTPClient(baseURL: baseURL, authorization: HTTPClient.bearer(token))
    }

    public func merges(repo path: String) throws -> [PullRequest] {
        let parts = path.split(separator: "/")
        guard parts.count == 2 else { throw MergeGongError("Repo non valido: \(path)") }
        return try Self.decodeMerges(client.get(
            "rest/api/1.0/projects/\(parts[0])/repos/\(parts[1])/pull-requests?state=MERGED&order=NEWEST&limit=30"))
    }

    public func repos() throws -> [String] {
        try Self.decodeRepos(client.get("rest/api/1.0/profile/recent/repos?limit=30"))
    }

    private struct Pull: Decodable {
        struct Author: Decodable {
            struct User: Decodable { let displayName: String }
            let user: User
        }
        struct Ref: Decodable { let displayId: String }
        struct Links: Decodable {
            struct Link: Decodable { let href: URL }
            let `self`: [Link]
        }

        let id: Int
        let title: String
        let author: Author
        let toRef: Ref
        let links: Links
        /// Milliseconds since 1970.
        let closedDate: Double?
        let updatedDate: Double
    }

    private struct Repo: Decodable {
        struct Project: Decodable { let key: String }
        let slug: String
        let project: Project
    }

    static func decodeMerges(_ data: Data) throws -> [PullRequest] {
        try JSONDecoder.api().decode(Page<Pull>.self, from: data).values.map { pull in
            PullRequest(number: pull.id, title: pull.title, author: pull.author.user.displayName,
                        branch: pull.toRef.displayId, url: pull.links.`self`.first?.href,
                        mergedAt: Date(timeIntervalSince1970: (pull.closedDate ?? pull.updatedDate) / 1000))
        }
    }

    static func decodeRepos(_ data: Data) throws -> [String] {
        try JSONDecoder.api().decode(Page<Repo>.self, from: data).values.map { "\($0.project.key)/\($0.slug)" }
    }
}
