import Foundation
import Observation

/// Reads launchd and /health on a loop. Keeps no on/off flag, so it always agrees with the `qwen` shell function.
@MainActor @Observable
final class ServerModel {
    private(set) var state: ServerState = .off
    /// A failed launchctl call, shown as the status line until the next poll.
    private(set) var error: String?
    private var loadingSince: Date?

    init() {
        Task { await pollForever() }
    }

    private func pollForever() async {
        while true {
            await refresh()
            try? await Task.sleep(for: .seconds(state == .loading ? 2 : 5))
        }
    }

    func refresh(keepError: Bool = false) async {
        let loaded = await launchctl(["print", "\(Server.domain)/\(Server.label)"]).status == 0
        let code = loaded ? await healthCode() : nil
        let now = Date()
        loadingSince = loaded && code != 200 ? (loadingSince ?? now) : nil
        state = QwenLocal.state(jobLoaded: loaded, healthCode: code, loadingSince: loadingSince, now: now)
        if !keepError { error = nil }
    }

    func toggle() async {
        if state == .off {
            let result = await launchctl(["bootstrap", Server.domain, Server.plistPath])
            // "5: Input/output error" means the job is already loaded: that is "on", not a failure.
            if result.status != 0 && !result.output.contains("5: Input/output error") {
                error = "Turn On failed: \(result.output.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
        } else {
            let result = await launchctl(["bootout", "\(Server.domain)/\(Server.label)"])
            if result.status != 0 {
                error = "Turn Off failed: \(result.output.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
        }
        await refresh(keepError: true)
    }
}
