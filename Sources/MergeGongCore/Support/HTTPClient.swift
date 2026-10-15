import Foundation

/// Blocking JSON GETs against one API. Callers run on a background queue.
struct HTTPClient {
    let baseURL: URL
    /// Nil for public endpoints.
    let authorization: String?

    static func basic(user: String, password: String) -> String {
        "Basic " + Data("\(user):\(password)".utf8).base64EncodedString()
    }

    static func bearer(_ token: String) -> String {
        "Bearer \(token)"
    }

    /// A self-hosted server's address as typed by the user, with the trailing slash relative paths need.
    static func baseURL(from address: String) -> URL? {
        let trimmed = address.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed.hasSuffix("/") ? trimmed : trimmed + "/"),
              url.scheme == "https" || url.scheme == "http", url.host != nil else { return nil }
        return url
    }

    /// `path` is relative to `baseURL` and may carry a query string.
    func get(_ path: String) throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw MergeGongError("URL non valido: \(path)")
        }
        return try get(url: url)
    }

    func get(url: URL) throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var result: Result<(Data, URLResponse), Error>!
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let response, error == nil {
                result = .success((data ?? Data(), response))
            } else {
                result = .failure(error ?? URLError(.badServerResponse))
            }
            done.signal()
        }.resume()
        done.wait()

        let (data, response) = try result.get()
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw MergeGongError.http(status) }
        return data
    }
}
