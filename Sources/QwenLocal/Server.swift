import Foundation

enum Server {
    static let label = "mp.kaio.qwen"
    static let plistPath = home(".local/llama.cpp/mp.kaio.qwen.plist").path
    static let logURL = home("Library/Logs/qwen-server.log")
    static let chatURL = URL(string: "http://127.0.0.1:8080/")!
    static let healthURL = URL(string: "http://127.0.0.1:8080/health")!
    static let apiAddress = "http://127.0.0.1:8080/v1"
    static let stuckAfter: TimeInterval = 5 * 60
    static var domain: String { "gui/\(getuid())" }

    private static func home(_ path: String) -> URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: path)
    }
}

enum ServerState: Equatable {
    case off, loading, running, stuck

    /// One base symbol, so the icon is easy to swap.
    static let baseSymbol = "cpu"

    var symbol: String {
        switch self {
        case .off, .loading: Self.baseSymbol
        case .running: Self.baseSymbol + ".fill"
        case .stuck: "exclamationmark.triangle"
        }
    }

    var statusText: String {
        switch self {
        case .off: "Qwen: Off"
        case .loading: "Qwen: Loading… (about 2 min)"
        case .running: "Qwen: Running"
        case .stuck: "Qwen: Not ready after 5 min — check the log"
        }
    }
}

func state(jobLoaded: Bool, healthCode: Int?, loadingSince: Date?, now: Date) -> ServerState {
    guard jobLoaded else { return .off }
    if healthCode == 200 { return .running }
    if let loadingSince, now.timeIntervalSince(loadingSince) > Server.stuckAfter { return .stuck }
    return .loading
}

struct CommandResult: Sendable {
    let status: Int32
    let output: String
}

func launchctl(_ arguments: [String]) async -> CommandResult {
    await Task.detached {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do { try process.run() } catch {
            return CommandResult(status: -1, output: error.localizedDescription)
        }
        // Read before waiting: `launchctl print` can fill the pipe buffer and block.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return CommandResult(status: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }.value
}

func healthCode() async -> Int? {
    let request = URLRequest(url: Server.healthURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 1.5)
    guard let (_, response) = try? await URLSession.shared.data(for: request) else { return nil }
    return (response as? HTTPURLResponse)?.statusCode
}
