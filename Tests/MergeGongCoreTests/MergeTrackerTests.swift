import Foundation
import Testing
@testable import MergeGongCore

struct MergeTrackerTests {
    private let app = RepoRef(provider: .github, path: "acme/app")
    private let api = RepoRef(provider: .bitbucketCloud, path: "acme/api")

    private func pr(_ number: Int, at seconds: TimeInterval = 0) -> PullRequest {
        PullRequest(number: number, title: "PR \(number)", author: "luca", branch: "main", url: nil,
                    mergedAt: Date(timeIntervalSince1970: seconds))
    }

    @Test func firstRoundOnlyPrimes() {
        var tracker = MergeTracker()
        #expect(tracker.record([pr(1), pr(2)], repo: app).isEmpty)
        #expect(tracker.recent.count == 2)
    }

    @Test func laterRoundsReturnOnlyNewMerges() {
        var tracker = MergeTracker()
        _ = tracker.record([pr(1)], repo: app)
        #expect(tracker.record([pr(2), pr(1)], repo: app).map(\.pr.number) == [2])
        #expect(tracker.record([pr(2), pr(1)], repo: app).isEmpty)
    }

    @Test func reposArePrimedSeparately() {
        var tracker = MergeTracker()
        _ = tracker.record([pr(1)], repo: app)
        #expect(tracker.record([pr(1)], repo: api).isEmpty)
        #expect(tracker.record([pr(2), pr(1)], repo: api).map(\.repo) == [api])
    }

    @Test func recentIsNewestFirstAndCapped() {
        var tracker = MergeTracker()
        _ = tracker.record((1...6).map { pr($0, at: Double($0)) }, repo: app)
        _ = tracker.record((7...10).map { pr($0, at: Double($0)) }, repo: api)
        #expect(tracker.recent.count == MergeTracker.recentLimit)
        #expect(tracker.recent.first?.pr.number == 10)
        #expect(tracker.recent.last?.pr.number == 3)
    }
}
