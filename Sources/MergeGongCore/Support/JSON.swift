import Foundation

extension JSONDecoder {
    /// snake_case keys and ISO 8601 dates, with or without fractional seconds.
    static func api() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = parseISODate(string) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Data non valida: \(string)"))
            }
            return date
        }
        return decoder
    }
}

/// Bitbucket sends microseconds, which `ISO8601DateFormatter` rejects, so the fraction is dropped.
func parseISODate(_ string: String) -> Date? {
    let trimmed = string.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
    return ISO8601DateFormatter().date(from: trimmed)
}

/// A page of Bitbucket results (Cloud and Data Center both wrap lists in `values`).
struct Page<Value: Decodable>: Decodable {
    let values: [Value]
}
