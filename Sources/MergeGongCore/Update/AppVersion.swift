import Foundation

/// A release version such as `1.0.3`. Tags may carry a leading `v`; missing parts count as 0, so `1.0` == `1.0.0`.
public struct AppVersion: Comparable, CustomStringConvertible {
    public let parts: [Int]

    public init?(_ string: String) {
        let trimmed = string.hasPrefix("v") ? String(string.dropFirst()) : string
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        guard !parts.isEmpty, !parts.contains(nil) else { return nil }
        self.parts = parts.compactMap { $0 }
    }

    public var description: String { parts.map(String.init).joined(separator: ".") }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        for (l, r) in lhs.padded(to: rhs) where l != r { return l < r }
        return false
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.padded(to: rhs).allSatisfy { $0 == $1 }
    }

    private func padded(to other: AppVersion) -> Zip2Sequence<[Int], [Int]> {
        let count = max(parts.count, other.parts.count)
        let pad = { (parts: [Int]) in parts + Array(repeating: 0, count: count - parts.count) }
        return zip(pad(parts), pad(other.parts))
    }
}
