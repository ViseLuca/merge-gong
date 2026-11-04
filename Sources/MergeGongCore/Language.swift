import Foundation

/// The languages the app speaks. Italian for Italian systems, English everywhere else, unless the user picks one.
public enum Language: String, CaseIterable {
    case italian = "it"
    case english = "en"

    /// The language's name in itself, for the menu.
    public var nativeName: String {
        switch self {
        case .italian: "Italiano"
        case .english: "English"
        }
    }

    /// The first of the user's preferred languages the app speaks; English if none.
    public static func resolve(preferred: [String]) -> Language {
        for identifier in preferred {
            let code = identifier.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map { $0.lowercased() }
            if let language = code.flatMap(Language.init(rawValue:)) { return language }
        }
        return .english
    }

    /// The system's choice, ignoring the user's override.
    public static var system: Language {
        resolve(preferred: Locale.preferredLanguages)
    }

    /// The language in use: the one picked in the menu, or the system's. Read from UserDefaults on every call,
    /// so it is safe from any thread and a change shows up the next time a text is built.
    public static var current: Language {
        Settings().language ?? system
    }
}

/// Picks the Italian or English text for the current language.
public func tr(_ italian: String, _ english: String) -> String {
    Language.current == .italian ? italian : english
}
