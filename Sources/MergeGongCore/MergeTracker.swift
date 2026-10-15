import Foundation

/// Remembers which merges were already seen, so only new ones ring the gong.
public struct MergeTracker {
    public static let recentLimit = 8

    /// Latest merges across all repos, newest first.
    public private(set) var recent: [Merge] = []
    private var seen: [RepoRef: Set<Int>] = [:]
    private var primed = Set<RepoRef>()

    public init() {}

    /// Records the repo's merges and returns the new ones. The first call for a repo only records what is
    /// already there and returns nothing, so starting up does not set off a gong storm.
    public mutating func record(_ prs: [PullRequest], repo: RepoRef) -> [Merge] {
        let known = seen[repo, default: []]
        let merges = prs.map { Merge(repo: repo, pr: $0) }
        seen[repo, default: []].formUnion(prs.map(\.number))
        recent = Array((recent.filter { $0.repo != repo } + merges)
            .sorted { $0.pr.mergedAt > $1.pr.mergedAt }
            .prefix(Self.recentLimit))
        guard !primed.insert(repo).inserted else { return [] }
        return merges.filter { !known.contains($0.pr.number) }
    }
}
