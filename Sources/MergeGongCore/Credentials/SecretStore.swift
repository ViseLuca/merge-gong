import Foundation

/// Service tokens, kept in the Keychain. A token saved as a 1Password reference (`op://Vault/Item/Field`)
/// is read with the `op` CLI each time it is needed, so the secret itself never leaves 1Password at rest.
public struct SecretStore {
    private let keychain: Keychain

    public init(keychain: Keychain = Keychain()) {
        self.keychain = keychain
    }

    public func save(_ token: String, for kind: ProviderKind) throws {
        try keychain.set(token, account: kind.rawValue)
    }

    public func remove(for kind: ProviderKind) throws {
        try keychain.remove(kind.rawValue)
    }

    public func hasToken(for kind: ProviderKind) -> Bool {
        (try? keychain.get(kind.rawValue)) != nil
    }

    public func token(for kind: ProviderKind) throws -> String? {
        guard let value = try keychain.get(kind.rawValue) else { return nil }
        guard Self.isOnePasswordReference(value) else { return value }
        guard let op = ProcessRunner.find("op") else {
            throw MergeGongError("1Password CLI (op) non trovato. Installa con: brew install 1password-cli")
        }
        return String(decoding: try ProcessRunner.run(op, ["read", "--no-newline", value]), as: UTF8.self)
    }

    public static func isOnePasswordReference(_ value: String) -> Bool {
        value.hasPrefix("op://")
    }
}
