import Foundation

/// A published GitHub release of Merge Gong and its downloadable app.
public struct Release: Equatable {
    public let version: AppVersion
    /// The release page, for updating by hand.
    public let page: URL
    public let download: URL
    /// Hex SHA-256 of the download, when GitHub reports it.
    public let sha256: String?

    private struct Payload: Decodable {
        struct Asset: Decodable {
            let name: String
            let browserDownloadUrl: URL
            let digest: String?
        }

        let tagName: String
        let htmlUrl: URL
        let assets: [Asset]
    }

    static func decode(_ data: Data) throws -> Release {
        let payload = try JSONDecoder.api().decode(Payload.self, from: data)
        guard let version = AppVersion(payload.tagName) else {
            throw MergeGongError("Versione della release non valida: \(payload.tagName)")
        }
        guard let asset = payload.assets.first(where: { $0.name == Updater.assetName }) else {
            throw MergeGongError("La release \(payload.tagName) non contiene \(Updater.assetName)")
        }
        let sha256 = asset.digest.flatMap { $0.hasPrefix("sha256:") ? String($0.dropFirst("sha256:".count)) : nil }
        return Release(version: version, page: payload.htmlUrl, download: asset.browserDownloadUrl, sha256: sha256)
    }
}
