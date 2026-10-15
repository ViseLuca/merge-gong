import Foundation
import Testing
@testable import MergeGongCore

struct SettingsTests {
    private func makeDefaults() -> UserDefaults {
        let name = "merge-gong-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func repoKeysRoundTrip() {
        for repo in [RepoRef(provider: .github, path: "acme/app"),
                     RepoRef(provider: .bitbucketCloud, path: "acme/api"),
                     RepoRef(provider: .bitbucketServer, path: "~LUCA/dots")] {
            #expect(RepoRef(key: repo.key) == repo)
        }
    }

    @Test func unprefixedKeysAreGitHub() {
        #expect(RepoRef(key: "acme/app") == RepoRef(provider: .github, path: "acme/app"))
    }

    @Test func invalidKeysAreDropped() {
        #expect(RepoRef(key: "gitlab:acme/app") == nil)
        #expect(RepoRef(key: "bitbucket:no-slash") == nil)
    }

    @Test func migratesGitHubOnlySettings() {
        let defaults = makeDefaults()
        defaults.set(["acme/app"], forKey: "repos")
        let settings = Settings(defaults: defaults)
        settings.migrate()
        #expect(settings.enabledProviders == [.github])
        #expect(defaults.stringArray(forKey: "repos") == ["github:acme/app"])
    }

    @Test func freshInstallStillNeedsSetup() {
        let settings = Settings(defaults: makeDefaults())
        settings.migrate()
        #expect(settings.enabledProviders == nil)
    }
}
