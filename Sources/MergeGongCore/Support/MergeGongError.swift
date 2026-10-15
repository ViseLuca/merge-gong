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
        case 401: MergeGongError("Credenziali non valide (401)")
        case 403: MergeGongError("Permessi insufficienti (403): controlla gli scope del token")
        case 404: MergeGongError("Non trovato (404)")
        case 429: MergeGongError("Troppe richieste (429): limite API raggiunto")
        default: MergeGongError("Errore HTTP \(status)")
        }
    }
}
