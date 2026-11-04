import MergeGongCore

/// Every piece of UI text, in Italian and English. Computed on every read so a language change in the menu
/// shows up the next time a text is built; the gong is universal.
enum L10n {
    static let gong = "GONG!"
    static let ok = "OK"
    static var cancel: String { tr("Annulla", "Cancel") }
    static var retry: String { tr("Riprova", "Retry") }

    // Menu
    static var noRepos: String { tr("Nessun repo scelto", "No repos selected") }
    static func listening(_ count: Int) -> String {
        tr("In ascolto su \(count) repo", count == 1 ? "Listening to 1 repo" : "Listening to \(count) repos")
    }
    static func branch(_ name: String?) -> String { "Branch: \(name ?? tr("tutti", "all"))" }
    static var recentMerges: String { tr("Ultimi merge", "Recent merges") }
    static var reposMenu: String { tr("Repo da ascoltare", "Repos to watch") }
    static var addRepo: String { tr("Aggiungi altro repo…", "Add another repo…") }
    static var noServices: String { tr("Nessun servizio collegato", "No services connected") }
    static var services: String { tr("Servizi collegati", "Connected services") }
    static var connected: String { tr("Collegato", "Connected") }
    static var configure: String { tr("Configura…", "Configure…") }
    static var connect: String { tr("Collega…", "Connect…") }
    static var disconnect: String { tr("Scollega", "Disconnect") }
    static var filterBranch: String { tr("Filtra branch…", "Filter branch…") }
    static var strike: String { tr("Suona il gong", "Strike the gong") }
    static var openAtLogin: String { tr("Apri al login", "Open at login") }
    static var language: String { tr("Lingua", "Language") }
    static var languageAuto: String { tr("Automatica (sistema)", "Automatic (system)") }
    static var github: String { tr("Merge Gong su GitHub", "Merge Gong on GitHub") }
    static var quit: String { tr("Esci", "Quit") }

    // Prompts
    static var addRepoPrompt: String { tr("Repo da aggiungere", "Repo to add") }
    static var branchPrompt: String {
        tr("Suona solo per merge su questo branch (vuoto = tutti)", "Only ring for merges into this branch (empty = all)")
    }
    static let branchHint = "env/prod"
    static var testTitle: String { tr("Prova del gong", "Gong test") }
    static var noRepo: String { tr("nessun repo", "no repo") }

    // Setup
    static var setupTitle: String { tr("Cosa vuoi collegare?", "What do you want to connect?") }
    static var setupInfo: String {
        tr("Merge Gong suona quando una pull request viene mergiata. Scegli dove ascoltare: puoi cambiare quando vuoi da “\(services)”.",
           "Merge Gong rings when a pull request gets merged. Choose where to listen: you can change it any time from “\(services)”.")
    }
    static func connectTitle(_ kind: ProviderKind) -> String { tr("Collega \(kind.displayName)", "Connect \(kind.displayName)") }
    static var tokenHint: String { tr("token oppure op://Vault/Item/Field", "token or op://Vault/Item/Field") }
    static var tokenKeep: String { tr("vuoto = mantieni quello salvato", "empty = keep the saved one") }
    static var missingFields: String { tr("Compila tutti i campi.", "Fill in all the fields.") }
    static func connectionFailed(_ kind: ProviderKind) -> String {
        tr("Connessione a \(kind.displayName) non riuscita", "Could not connect to \(kind.displayName)")
    }
    static func disconnectTitle(_ kind: ProviderKind) -> String {
        tr("Scollegare \(kind.displayName)?", "Disconnect \(kind.displayName)?")
    }
    static var disconnectInfo: String {
        tr("Il token viene tolto dal Portachiavi e i repo di questo servizio non vengono più ascoltati.",
           "The token is removed from the Keychain and this service's repos are no longer watched.")
    }

    // Login item
    static var loginItemFailed: String {
        tr("Impossibile cambiare l'apertura al login", "Could not change the open at login setting")
    }
    static var loginNeedsApproval: String { tr("Da attivare in Impostazioni di Sistema", "Turn it on in System Settings") }
    static var loginNeedsApprovalInfo: String {
        tr("Merge Gong è negli Elementi login ma è spento. Accendilo nella finestra che si apre.",
           "Merge Gong is in Login Items but turned off. Turn it on in the window that opens.")
    }

    // Updates
    static func checkUpdates(_ version: String) -> String {
        tr("Controlla aggiornamenti… (\(version))", "Check for updates… (\(version))")
    }
    static func installUpdate(_ version: String) -> String { tr("⬆️ Aggiorna alla \(version)", "⬆️ Update to \(version)") }
    static var updating: String { tr("Aggiornamento in corso…", "Updating…") }
    static func updateAvailable(_ version: String) -> String {
        tr("È disponibile Merge Gong \(version)", "Merge Gong \(version) is available")
    }
    static func updateInfo(current: String) -> String {
        tr("Hai la \(current). L'aggiornamento si scarica da GitHub e l'app si riavvia da sola. Dopo, macOS potrebbe chiedere di nuovo l'accesso al Portachiavi.",
           "You have \(current). The update downloads from GitHub and the app restarts by itself. Afterwards, macOS may ask for Keychain access again.")
    }
    static var updateNow: String { tr("Aggiorna ora", "Update now") }
    static var upToDate: String { tr("Merge Gong è aggiornato", "Merge Gong is up to date") }
    static func upToDateInfo(_ version: String) -> String {
        tr("Hai l'ultima versione (\(version)).", "You have the latest version (\(version)).")
    }
    static var updateCheckFailed: String { tr("Controllo aggiornamenti non riuscito", "Could not check for updates") }
    static var updateFailed: String { tr("Aggiornamento non riuscito", "Update failed") }
    static var openReleasePage: String { tr("Apri la release", "Open the release") }
    static var cannotUpdate: String { tr("Merge Gong non può aggiornarsi da solo", "Merge Gong cannot update itself") }
    static var updateByHand: String {
        tr("Non ha i permessi per sostituirsi nella sua cartella. Scarica MergeGong.zip dalla pagina della release che si apre e sostituisci l'app.",
           "It is not allowed to replace itself in its folder. Download MergeGong.zip from the release page that opens and replace the app.")
    }
    static var updateInstalled: String { tr("Aggiornamento installato", "Update installed") }
    static var reopenByHand: String {
        tr("Riapri Merge Gong per usare la nuova versione.", "Reopen Merge Gong to use the new version.")
    }
}

extension ProviderKind {
    var repoHint: String {
        switch self {
        case .github: tr("owner/nome", "owner/name")
        case .gitlab: tr("gruppo/progetto", "group/project")
        case .bitbucketCloud: "workspace/repo"
        case .bitbucketServer: tr("PROGETTO/repo", "PROJECT/repo")
        }
    }

    var accountLabel: String {
        switch self {
        case .github: ""
        case .gitlab: tr("URL dell'istanza", "Instance URL")
        case .bitbucketCloud: tr("Email Atlassian", "Atlassian email")
        case .bitbucketServer: tr("URL del server", "Server URL")
        }
    }

    var accountHint: String {
        switch self {
        case .github: ""
        case .gitlab: "https://gitlab.com"
        case .bitbucketCloud: tr("nome@azienda.it", "name@company.com")
        case .bitbucketServer: tr("https://bitbucket.azienda.it", "https://bitbucket.company.com")
        }
    }

    /// The account field's starting value when nothing is saved yet.
    var defaultAccount: String? {
        self == .gitlab ? "https://gitlab.com" : nil
    }

    var tokenLabel: String {
        switch self {
        case .github: ""
        case .gitlab: "Personal access token"
        case .bitbucketCloud: "API token"
        case .bitbucketServer: "HTTP access token"
        }
    }

    var setupHelp: String {
        switch self {
        case .github:
            tr("Usa il login di gh (brew install gh, poi gh auth login).",
               "Uses the gh login (brew install gh, then gh auth login).")
        case .gitlab:
            tr("Lascia https://gitlab.com o indica l'URL della tua istanza self-managed. Crea un personal access token con scope read_api (Preferenze → Access tokens). Il token resta nel Portachiavi; puoi anche indicare un riferimento 1Password op://…",
               "Keep https://gitlab.com or enter your self-managed instance URL. Create a personal access token with the read_api scope (Preferences → Access tokens). The token stays in the Keychain; you can also enter a 1Password reference op://…")
        case .bitbucketCloud:
            tr("Crea un API token con scope su id.atlassian.com → Sicurezza → Token API, scegliendo Bitbucket e gli scope read:repository:bitbucket, read:pullrequest:bitbucket, read:workspace:bitbucket e read:user:bitbucket. Il token resta nel Portachiavi; puoi anche indicare un riferimento 1Password op://…",
               "Create an API token with scopes at id.atlassian.com → Security → API tokens, choosing Bitbucket and the scopes read:repository:bitbucket, read:pullrequest:bitbucket, read:workspace:bitbucket and read:user:bitbucket. The token stays in the Keychain; you can also enter a 1Password reference op://…")
        case .bitbucketServer:
            tr("Crea un HTTP access token dal tuo profilo Bitbucket (Gestisci account → HTTP access tokens) con permesso di lettura sui repository. Il token resta nel Portachiavi; puoi anche indicare un riferimento 1Password op://…",
               "Create an HTTP access token from your Bitbucket profile (Manage account → HTTP access tokens) with repository read permission. The token stays in the Keychain; you can also enter a 1Password reference op://…")
        }
    }
}

extension Merge {
    /// `@username` on GitHub and GitLab, the display name on Bitbucket.
    var authorLabel: String {
        [.github, .gitlab].contains(repo.provider) ? "@\(pr.author)" : pr.author
    }
}
