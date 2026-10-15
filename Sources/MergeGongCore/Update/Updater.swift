import CryptoKit
import Foundation

/// Updates the app in place from the latest GitHub release: the zip that `./build.sh dist` makes. Calls block:
/// run them off the main thread.
public struct Updater {
    static let repo = "ViseLuca/merge-gong"
    static let assetName = "MergeGong.zip"

    private let bundle: Bundle
    private let client = HTTPClient(baseURL: URL(string: "https://api.github.com/")!, authorization: nil)

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public var appURL: URL { bundle.bundleURL }

    /// The running version; nil outside an app bundle (`swift run`), where there is nothing to update.
    public var currentVersion: AppVersion? {
        guard appURL.pathExtension == "app" else { return nil }
        return Self.version(of: bundle)
    }

    /// False when the app cannot replace itself, as for a translocated copy or one in a folder the user cannot write.
    public var canInstall: Bool {
        let files = FileManager.default
        return files.isWritableFile(atPath: appURL.path) && files.isWritableFile(atPath: appURL.deletingLastPathComponent().path)
    }

    /// The latest release, if newer than the running app. Unauthenticated: GitHub allows 60 calls per hour per IP.
    public func newerRelease() throws -> Release? {
        guard let current = currentVersion else { return nil }
        let release = try Release.decode(client.get("repos/\(Self.repo)/releases/latest"))
        return release.version > current ? release : nil
    }

    /// Downloads and checks `release`, then swaps it in for the app on disk. The running process keeps
    /// the old code until it is relaunched.
    public func install(_ release: Release) throws {
        let files = FileManager.default
        // On the app's volume, so the final swap is a rename.
        let staging = try files.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: appURL, create: true)
        defer { try? files.removeItem(at: staging) }

        let data = try client.get(url: release.download)
        if let expected = release.sha256 {
            let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard actual == expected.lowercased() else { throw MergeGongError("Download corrotto: checksum diverso") }
        }
        let zip = staging.appendingPathComponent(Self.assetName)
        try data.write(to: zip)
        _ = try ProcessRunner.run("/usr/bin/ditto", ["-x", "-k", zip.path, staging.path])

        guard let app = try files.contentsOfDirectory(at: staging, includingPropertiesForKeys: nil)
                  .first(where: { $0.pathExtension == "app" }),
              let downloaded = Bundle(url: app) else {
            throw MergeGongError("Lo zip della release non contiene l'app")
        }
        guard downloaded.bundleIdentifier == bundle.bundleIdentifier else {
            throw MergeGongError("Lo zip della release contiene un'altra app: \(downloaded.bundleIdentifier ?? "?")")
        }
        // An app that still reports an older version would be offered again on every check.
        guard let version = Self.version(of: downloaded), version == release.version else {
            throw MergeGongError("La release \(release.version) contiene l'app versione \(Self.version(of: downloaded)?.description ?? "?")")
        }
        _ = try ProcessRunner.run("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
        _ = try files.replaceItemAt(appURL, withItemAt: app)
    }

    private static func version(of bundle: Bundle) -> AppVersion? {
        (bundle.infoDictionary?["CFBundleShortVersionString"] as? String).flatMap(AppVersion.init)
    }
}
