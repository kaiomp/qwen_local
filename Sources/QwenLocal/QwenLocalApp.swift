import AppKit
import ServiceManagement
import SwiftUI

@main
struct QwenLocalApp: App {
    @State private var model = ServerModel()

    init() {
        // LSUIElement only covers the installed .app; this also hides the Dock icon under `swift run`.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            StatusIcon(state: model.state)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Monochrome template symbol. State shows by shape, never color (a colored dot reads as "recording" on screen share).
struct StatusIcon: View {
    let state: ServerState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: state.symbol)
            .symbolEffect(.pulse, isActive: state == .loading && !reduceMotion)
    }
}

struct MenuContent: View {
    let model: ServerModel
    @State private var openAtLogin = Self.loginEnabled

    var body: some View {
        Text(model.error ?? model.state.statusText)
        Button(model.state == .off ? "Turn On" : "Turn Off") {
            Task { await model.toggle() }
        }
        Divider()
        Button("Open Chat") { NSWorkspace.shared.open(Server.chatURL) }
            .disabled(model.state != .running)
        Button("Copy API Address") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(Server.apiAddress, forType: .string)
        }
        Divider()
        Button("Open Log") { NSWorkspace.shared.open(Server.logURL) }
        Toggle("Open at Login", isOn: Binding(get: { openAtLogin }, set: { setOpenAtLogin($0) }))
        Divider()
        Button("Quit QwenLocal") { NSApp.terminate(nil) }
    }

    /// Starts only the app at login, never the model.
    private func setOpenAtLogin(_ on: Bool) {
        try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        openAtLogin = Self.loginEnabled
    }

    private static var loginEnabled: Bool {
        [.enabled, .requiresApproval].contains(SMAppService.mainApp.status)
    }
}
