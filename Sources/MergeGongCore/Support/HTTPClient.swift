import Foundation

/// Blocking JSON GETs against one API. Callers run on a background queue.
struct HTTPClient {
    let baseURL: URL
    let authorization: String

    static func basic(user: String, password: String) -> String {
        "Basic " + Data("\(user):\(password)".utf8).base64EncodedString()
    }

    static func bearer(_ token: String) -> String {
        "Bearer \(token)"
    }

    /// `path` is relative to `baseURL` and may carry a query string.
    func get(_ path: String) throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw MergeGongError("URL non valido: \(path)")
        }
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
