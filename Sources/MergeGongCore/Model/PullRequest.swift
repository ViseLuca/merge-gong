import Foundation

/// A merged pull request, whatever service it comes from.
public struct PullRequest: Equatable {
    public let number: Int
    public let title: String
    public let author: String
    /// The branch it was merged into.
    public let branch: String
    public let url: URL?
    public let mergedAt: Date

    public init(number: Int, title: String, author: String, branch: String, url: URL?, mergedAt: Date) {
        self.number = number
        self.title = title
        self.author = author
        self.branch = branch
        self.url = url
        self.mergedAt = mergedAt
    }
}

/// A pull request merged on a watched repo.
public struct Merge: Equatable {
    public let repo: RepoRef
    public let pr: PullRequest

    public init(repo: RepoRef, pr: PullRequest) {
        self.repo = repo
        self.pr = pr
    }
}
