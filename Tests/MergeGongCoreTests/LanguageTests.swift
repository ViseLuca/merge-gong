import Foundation
import Testing
@testable import MergeGongCore

struct LanguageTests {
    @Test func picksFirstSpokenPreferredLanguage() {
        #expect(Language.resolve(preferred: ["it-IT", "en-US"]) == .italian)
        #expect(Language.resolve(preferred: ["en-GB", "it-IT"]) == .english)
        #expect(Language.resolve(preferred: ["de-DE", "it_CH", "en"]) == .italian)
        #expect(Language.resolve(preferred: ["IT"]) == .italian)
    }

    @Test func fallsBackToEnglish() {
        #expect(Language.resolve(preferred: ["fr-FR", "de"]) == .english)
        #expect(Language.resolve(preferred: []) == .english)
    }

    @Test func languageChoiceRoundTrips() {
        let name = "merge-gong-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = Settings(defaults: defaults)
        #expect(settings.language == nil)
        settings.language = .english
        #expect(settings.language == .english)
        settings.language = nil
        #expect(settings.language == nil)
        defaults.set("klingon", forKey: "language")
        #expect(settings.language == nil)
    }
}
