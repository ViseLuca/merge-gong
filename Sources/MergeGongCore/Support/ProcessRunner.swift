import Foundation

/// Runs command line tools such as `gh` and `op`.
enum ProcessRunner {
    /// The tool's path in the usual Homebrew and system locations, which a GUI app's PATH lacks.
    static func find(_ name: String) -> String? {
        ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"]
            .map { "\($0)/\(name)" }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Returns stdout, or throws with stderr as the message when the tool fails.
    static func run(_ path: String, _ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        try process.run()

        // Drain stderr alongside stdout: a full pipe would block the tool forever.
        var errData = Data()
        let stderrDone = DispatchGroup()
        stderrDone.enter()
        DispatchQueue.global().async {
            errData = err.fileHandleForReading.readDataToEndOfFile()
            stderrDone.leave()
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        stderrDone.wait()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw MergeGongError(String(decoding: errData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return data
    }
}
