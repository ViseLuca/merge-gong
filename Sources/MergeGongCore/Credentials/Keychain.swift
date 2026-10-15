import Foundation
import Security

/// Generic passwords in the user's login Keychain.
public struct Keychain {
    public let service: String

    public init(service: String = "merge-gong") {
        self.service = service
    }

    public func get(_ account: String) throws -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        try check(status)
        return (item as? Data).map { String(decoding: $0, as: UTF8.self) }
    }

    public func set(_ value: String, account: String) throws {
        let data = Data(value.utf8)
        let status = SecItemUpdate(baseQuery(account) as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        guard status == errSecItemNotFound else { return try check(status) }
        var query = baseQuery(account)
        query[kSecValueData as String] = data
        try check(SecItemAdd(query as CFDictionary, nil))
    }

    public func remove(_ account: String) throws {
        let status = SecItemDelete(baseQuery(account) as CFDictionary)
        if status != errSecItemNotFound { try check(status) }
    }

    private func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else {
            let reason = SecCopyErrorMessageString(status, nil) as String? ?? "codice \(status)"
            throw MergeGongError("Portachiavi: \(reason)")
        }
    }
}
