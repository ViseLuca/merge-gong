import MergeGongCore

/// Every piece of UI text. The app speaks Italian; the gong is universal.
enum L10n {
    static let gong = "GONG!"
    static let ok = "OK"
    static let cancel = "Annulla"
    static let retry = "Riprova"

    // Menu
    static let noRepos = "Nessun repo scelto"
    static func listening(_ count: Int) -> String { "In ascolto su \(count) repo" }
    static func branch(_ name: String?) -> String { "Branch: \(name ?? "tutti")" }
    static let recentMerges = "Ultimi merge"
    static let reposMenu = "Repo da ascoltare"
    static let addRepo = "Aggiungi altro repo…"
    static let noServices = "Nessun servizio collegato"
    static let services = "Servizi collegati"
    static let connected = "Collegato"
    static let configure = "Configura…"
    static let connect = "Collega…"
    static let disconnect = "Scollega"
    static let filterBranch = "Filtra branch…"
    static let strike = "Suona il gong"
    static let quit = "Esci"

    // Prompts
    static let addRepoPrompt = "Repo da aggiungere"
    static let branchPrompt = "Suona solo per merge su questo branch (vuoto = tutti)"
    static let branchHint = "env/prod"
    static let testTitle = "Prova del gong"
    static let noRepo = "nessun repo"

    // Setup
    static let setupTitle = "Cosa vuoi collegare?"
    static let setupInfo = "Merge Gong suona quando una pull request viene mergiata. Scegli dove ascoltare: puoi cambiare quando vuoi da “Servizi collegati”."
    static func connectTitle(_ kind: ProviderKind) -> String { "Collega \(kind.displayName)" }
    static let tokenHint = "token oppure op://Vault/Item/Field"
    static let tokenKeep = "vuoto = mantieni quello salvato"
    static let missingFields = "Compila tutti i campi."
    static func connectionFailed(_ kind: ProviderKind) -> String { "Connessione a \(kind.displayName) non riuscita" }
    static func disconnectTitle(_ kind: ProviderKind) -> String { "Scollegare \(kind.displayName)?" }
    static let disconnectInfo = "Il token viene tolto dal Portachiavi e i repo di questo servizio non vengono più ascoltati."

    // Updates
    static func checkUpdates(_ version: String) -> String { "Controlla aggiornamenti… (\(version))" }
    static func installUpdate(_ version: String) -> String { "⬆️ Aggiorna alla \(version)" }
    static let updating = "Aggiornamento in corso…"
    static func updateAvailable(_ version: String) -> String { "È disponibile Merge Gong \(version)" }
    static func updateInfo(current: String) -> String {
        "Hai la \(current). L'aggiornamento si scarica da GitHub e l'app si riavvia da sola. Dopo, macOS potrebbe chiedere di nuovo l'accesso al Portachiavi."
    }
    static let updateNow = "Aggiorna ora"
    static let upToDate = "Merge Gong è aggiornato"
    static func upToDateInfo(_ version: String) -> String { "Hai l'ultima versione (\(version))." }
    static let updateCheckFailed = "Controllo aggiornamenti non riuscito"
    static let updateFailed = "Aggiornamento non riuscito"
    static let openReleasePage = "Apri la release"
    static let cannotUpdate = "Merge Gong non può aggiornarsi da solo"
    static let updateByHand = "Non ha i permessi per sostituirsi nella sua cartella. Scarica MergeGong.zip dalla pagina della release che si apre e sostituisci l'app."
    static let updateInstalled = "Aggiornamento installato"
    static let reopenByHand = "Riapri Merge Gong per usare la nuova versione."
}

extension ProviderKind {
    var repoHint: String {
        switch self {
        case .github: "owner/nome"
        case .gitlab: "gruppo/progetto"
        case .bitbucketCloud: "workspace/repo"
        case .bitbucketServer: "PROGETTO/repo"
        }
    }

    var accountLabel: String {
        switch self {
        case .github: ""
        case .gitlab: "URL dell'istanza"
        case .bitbucketCloud: "Email Atlassian"
        case .bitbucketServer: "URL del server"
        }
    }

    var accountHint: String {
        switch self {
        case .github: ""
        case .gitlab: "https://gitlab.com"
        case .bitbucketCloud: "nome@azienda.it"
        case .bitbucketServer: "https://bitbucket.azienda.it"
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
            "Usa il login di gh (brew install gh, poi gh auth login)."
        case .gitlab:
            "Lascia https://gitlab.com o indica l'URL della tua istanza self-managed. Crea un personal access token con scope read_api (Preferenze → Access tokens). Il token resta nel Portachiavi; puoi anche indicare un riferimento 1Password op://…"
        case .bitbucketCloud:
            "Crea un API token con scope su id.atlassian.com → Sicurezza → Token API, scegliendo Bitbucket e gli scope read:repository:bitbucket, read:pullrequest:bitbucket, read:workspace:bitbucket e read:user:bitbucket. Il token resta nel Portachiavi; puoi anche indicare un riferimento 1Password op://…"
        case .bitbucketServer:
            "Crea un HTTP access token dal tuo profilo Bitbucket (Gestisci account → HTTP access tokens) con permesso di lettura sui repository. Il token resta nel Portachiavi; puoi anche indicare un riferimento 1Password op://…"
        }
    }
}

extension Merge {
    /// `@username` on GitHub and GitLab, the display name on Bitbucket.
    var authorLabel: String {
        [.github, .gitlab].contains(repo.provider) ? "@\(pr.author)" : pr.author
    }
}
