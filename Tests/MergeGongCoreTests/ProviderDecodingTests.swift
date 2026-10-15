import Foundation
import Testing
@testable import MergeGongCore

struct ProviderDecodingTests {
    @Test func gitHubKeepsOnlyMergedPulls() throws {
        let json = """
        [
          {"number": 12, "title": "Add gong", "merged_at": "2026-10-01T09:30:00Z",
           "html_url": "https://github.com/acme/app/pull/12", "user": {"login": "luca"}, "base": {"ref": "main"}},
          {"number": 13, "title": "Closed unmerged", "merged_at": null,
           "html_url": "https://github.com/acme/app/pull/13", "user": {"login": "luca"}, "base": {"ref": "main"}}
        ]
        """
        let prs = try GitHubProvider.decodeMerges(Data(json.utf8))
        #expect(prs == [PullRequest(number: 12, title: "Add gong", author: "luca", branch: "main",
                                    url: URL(string: "https://github.com/acme/app/pull/12"),
                                    mergedAt: try #require(parseISODate("2026-10-01T09:30:00Z")))])
    }

    @Test func gitHubRepos() throws {
        let json = #"[{"full_name": "acme/app"}, {"full_name": "acme/api"}]"#
        #expect(try GitHubProvider.decodeRepos(Data(json.utf8)) == ["acme/app", "acme/api"])
    }

    @Test func bitbucketCloudPulls() throws {
        let json = """
        {"pagelen": 30, "values": [
          {"id": 7, "title": "Fix login", "state": "MERGED",
           "author": {"display_name": "Luca Visentin", "nickname": "luca"},
           "destination": {"branch": {"name": "env/prod"}},
           "links": {"html": {"href": "https://bitbucket.org/acme/app/pull-requests/7"}},
           "updated_on": "2026-10-02T14:05:06.123456+00:00"},
          {"id": 8, "title": "Ghost author", "author": null,
           "destination": {"branch": {"name": "main"}},
           "links": {"html": {"href": "https://bitbucket.org/acme/app/pull-requests/8"}},
           "updated_on": "2026-10-02T15:00:00+00:00"}
        ]}
        """
        let prs = try BitbucketCloudProvider.decodeMerges(Data(json.utf8))
        #expect(prs.map(\.number) == [7, 8])
        #expect(prs[0].author == "Luca Visentin")
        #expect(prs[0].branch == "env/prod")
        #expect(prs[0].url == URL(string: "https://bitbucket.org/acme/app/pull-requests/7"))
        #expect(prs[0].mergedAt == parseISODate("2026-10-02T14:05:06Z"))
        #expect(prs[1].author == "?")
    }

    @Test func bitbucketCloudWorkspacesInBothShapes() throws {
        let nested = #"{"values": [{"type": "workspace_access", "workspace": {"slug": "acme"}}]}"#
        let flat = #"{"values": [{"type": "workspace", "slug": "acme"}]}"#
        #expect(try BitbucketCloudProvider.decodeWorkspaces(Data(nested.utf8)) == ["acme"])
        #expect(try BitbucketCloudProvider.decodeWorkspaces(Data(flat.utf8)) == ["acme"])
    }

    @Test func bitbucketCloudRepos() throws {
        let json = #"{"values": [{"full_name": "acme/app", "updated_on": "2026-10-02T14:05:06.123456+00:00"}]}"#
        let repos = try BitbucketCloudProvider.decodeRepos(Data(json.utf8))
        #expect(repos.map(\.name) == ["acme/app"])
    }

    @Test func bitbucketServerPulls() throws {
        let json = """
        {"size": 1, "limit": 30, "isLastPage": true, "values": [
          {"id": 42, "title": "Release", "state": "MERGED",
           "author": {"user": {"name": "luca", "displayName": "Luca Visentin"}},
           "toRef": {"id": "refs/heads/main", "displayId": "main"},
           "links": {"self": [{"href": "https://git.acme.it/projects/APP/repos/core/pull-requests/42"}]},
           "closedDate": 1790000000000, "updatedDate": 1790000001000}
        ]}
        """
        let prs = try BitbucketServerProvider.decodeMerges(Data(json.utf8))
        #expect(prs == [PullRequest(number: 42, title: "Release", author: "Luca Visentin", branch: "main",
                                    url: URL(string: "https://git.acme.it/projects/APP/repos/core/pull-requests/42"),
                                    mergedAt: Date(timeIntervalSince1970: 1_790_000_000))])
    }

    @Test func bitbucketServerRepos() throws {
        let json = #"{"values": [{"slug": "core", "project": {"key": "APP"}}, {"slug": "dots", "project": {"key": "~LUCA"}}]}"#
        #expect(try BitbucketServerProvider.decodeRepos(Data(json.utf8)) == ["APP/core", "~LUCA/dots"])
    }

    @Test func bitbucketServerBaseURL() {
        #expect(BitbucketServerProvider.baseURL(from: "https://git.acme.it")?.absoluteString == "https://git.acme.it/")
        #expect(BitbucketServerProvider.baseURL(from: " https://acme.it/bitbucket/ ")?.absoluteString == "https://acme.it/bitbucket/")
        #expect(BitbucketServerProvider.baseURL(from: "git.acme.it") == nil)
    }
}
