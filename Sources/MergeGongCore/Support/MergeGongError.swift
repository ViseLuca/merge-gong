import Foundation

/// An error with a message ready for the menu.
public struct MergeGongError: LocalizedError, Equatable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }

    static func http(_ status: Int) -> MergeGongError {
        switch status {
        case 401: MergeGongError(tr("Credenziali non valide (401)", "Invalid credentials (401)"))
        case 403: MergeGongError(tr("Permessi insufficienti (403): controlla gli scope del token", "Insufficient permissions (403): check the token scopes"))
        case 404: MergeGongError(tr("Non trovato (404)", "Not found (404)"))
        case 429: MergeGongError(tr("Troppe richieste (429): limite API raggiunto", "Too many requests (429): API rate limit reached"))
        default: MergeGongError(tr("Errore HTTP \(status)", "HTTP error \(status)"))
        }
    }
}
