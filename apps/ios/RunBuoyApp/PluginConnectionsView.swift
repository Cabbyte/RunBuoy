import Foundation
import SwiftUI

struct PluginConnectionCode: Equatable, Sendable {
    let id: String
    let challenge: String

    static func decode(_ value: String) throws -> Self {
        guard let url = URLComponents(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "runbuoy", url.host == "connect", url.user == nil,
              url.password == nil, url.port == nil, url.fragment == nil,
              url.path.range(of: "^/pca_[a-f0-9]{32}$", options: .regularExpression) != nil,
              let items = url.queryItems, items.count == 1, items[0].name == "challenge",
              let challenge = items[0].value,
              challenge.range(of: "^pcc_[A-Za-z0-9_-]{43}$", options: .regularExpression) != nil
        else { throw APIError.invalidURL }
        return Self(id: String(url.path.dropFirst()), challenge: challenge)
    }
}

struct PluginConnection: Decodable, Identifiable, Sendable {
    let id: String
    let clientName: String
    let scopes: [String]
    let createdAt: Date
    let expiresAt: Date
    enum CodingKeys: String, CodingKey {
        case id, scopes
        case clientName = "client_name", createdAt = "created_at", expiresAt = "expires_at"
    }
}

struct PluginConnectionRequest: Decodable, Sendable {
    let id: String
    let clientName: String
    let origin: String
    let workspaceID: String
    let scopes: [String]
    let status: String
    let expiresAt: Date
    var hasReadOnlyScopes: Bool {
        Set(scopes) == Set(["runs:read", "machines:read", "notifications:read"])
    }
    enum CodingKeys: String, CodingKey {
        case id, origin, scopes, status
        case clientName = "client_name", workspaceID = "workspace_id", expiresAt = "expires_at"
    }
}

// Older preview/test clients need not implement a server feature that is disabled by default.
extension RunBuoyAPI {
    func pluginConnections() async throws -> [PluginConnection] { throw APIError.httpStatus(404) }
    func inspectPluginConnection(_ code: PluginConnectionCode) async throws -> PluginConnectionRequest {
        throw APIError.httpStatus(404)
    }
    func decidePluginConnection(_ code: PluginConnectionCode, allow: Bool) async throws {
        throw APIError.httpStatus(404)
    }
    func revokePluginConnection(_ id: String) async throws { throw APIError.httpStatus(404) }
}

struct PluginConnectionsView: View {
    @Environment(RunBuoyStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var connections: [PluginConnection] = []
    @State private var request: PluginConnectionRequest?
    @State private var inspectedCode: PluginConnectionCode?
    @State private var pastedLink = ""
    @State private var scanning = false
    @State private var busy = false
    @State private var error: String?
    @State private var completion: String?
    @State private var revoking: PluginConnection?

    var body: some View {
        Form {
            if let identity = store.deviceIdentity {
                Section("plugin.workspace") {
                    Text(identity.workspaceID).font(.caption.monospaced()).textSelection(.enabled)
                        .accessibilityIdentifier("plugin.workspaceID")
                    ShareLink(item: identity.workspaceID) {
                        Label("plugin.share_workspace", systemImage: "square.and.arrow.up")
                    }
                }
            }
            if let error {
                Section { Label(error, systemImage: "exclamationmark.triangle") }
                    .foregroundStyle(.orange).accessibilityIdentifier("plugin.error")
            }
            if let completion {
                Section { Label(completion, systemImage: "checkmark.circle") }
                    .accessibilityIdentifier("plugin.completion")
            }
            if let request {
                consent(request)
            }
            Section("plugin.new") {
                Button("plugin.scan", systemImage: "qrcode.viewfinder") { scanning = true }
                    .accessibilityIdentifier("plugin.scan")
                TextField("plugin.paste", text: $pastedLink, axis: .vertical)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .privacySensitive().accessibilityIdentifier("plugin.link")
                Button("plugin.review") { receive(pastedLink) }
                    .disabled(pastedLink.isEmpty || busy).accessibilityIdentifier("plugin.review")
            }
            Section {
                if connections.isEmpty {
                    Text("plugin.empty").foregroundStyle(.secondary)
                }
                ForEach(connections) { connection in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(connection.clientName).font(.headline)
                        Text("plugin.read_only").font(.subheadline).foregroundStyle(.secondary)
                        LabeledContent("plugin.created") { Text(connection.createdAt, style: .date) }
                        LabeledContent("plugin.expires") { Text(connection.expiresAt, style: .date) }
                        Button("plugin.revoke", role: .destructive) { revoking = connection }
                            .disabled(busy).accessibilityIdentifier("plugin.revoke")
                    }
                }
                Button("plugin.reload") { Task { await load() } }.disabled(busy)
            } header: { Text("plugin.title") }
              footer: { Text("plugin.footer") }
        }
        .navigationTitle("plugin.title")
        .overlay { if busy { ProgressView().accessibilityLabel(Text("plugin.loading")) } }
        .sheet(isPresented: $scanning) {
            ScannerSheet { value in scanning = false; receive(value) }
        }
        .confirmationDialog("plugin.revoke_confirm", isPresented: Binding(
            get: { revoking != nil }, set: { if !$0 { revoking = nil } }
        ), titleVisibility: .visible) {
            if let connection = revoking {
                Button("plugin.revoke", role: .destructive) {
                    Task {
                        busy = true
                        defer { busy = false }
                        do { try await store.revokePluginConnection(connection.id); await load() }
                        catch { show(error) }
                    }
                }
                .accessibilityIdentifier("plugin.confirmRevoke")
            }
        } message: { Text("plugin.revoke_effect") }
        .task { await load() }
        .task(id: router.pendingPluginConnection?.challenge) { await inspectPending() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await load(); await inspectPending() } }
        }
    }

    private func consent(_ request: PluginConnectionRequest) -> some View {
        Section {
            Text(request.clientName).font(.title3.bold())
            LabeledContent("plugin.source", value: request.origin)
            LabeledContent("plugin.workspace", value: request.workspaceID).textSelection(.enabled)
            Text("plugin.permissions").fixedSize(horizontal: false, vertical: true)
            LabeledContent("plugin.expires") { Text(request.expiresAt, style: .time) }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let pending = request.status == "pending" && request.expiresAt > context.date
                if !pending { Text("plugin.expired").foregroundStyle(.secondary) }
                Button("plugin.allow") { Task { await decide(allow: true) } }
                    .buttonStyle(.borderless)
                    .disabled(busy || !pending || !request.hasReadOnlyScopes)
                    .accessibilityIdentifier("plugin.allow")
                Button("plugin.deny", role: .destructive) { Task { await decide(allow: false) } }
                    .buttonStyle(.borderless)
                    .disabled(busy || !pending).accessibilityIdentifier("plugin.deny")
            }
        } header: { Text("plugin.confirm") }
          footer: { Text("plugin.confirm_footer") }
    }

    private func receive(_ value: String) {
        do { router.pendingPluginConnection = try PluginConnectionCode.decode(value); pastedLink = "" }
        catch { show(error) }
    }

    private func inspectPending() async {
        guard let code = router.pendingPluginConnection else { return }
        request = nil; inspectedCode = nil; completion = nil; error = nil
        do {
            let result = try await store.inspectPluginConnection(code)
            guard router.pendingPluginConnection == code else { return }
            guard result.id == code.id, result.workspaceID == store.deviceIdentity?.workspaceID,
                  result.hasReadOnlyScopes else { throw APIError.invalidResponse }
            request = result; inspectedCode = code
        } catch { show(error) }
    }

    private func decide(allow: Bool) async {
        guard !busy, let code = inspectedCode, code == router.pendingPluginConnection else { return }
        busy = true
        defer { busy = false }
        do {
            try await store.decidePluginConnection(code, allow: allow)
            request = nil; inspectedCode = nil; router.pendingPluginConnection = nil
            completion = String(localized: allow ? "plugin.allowed" : "plugin.denied")
            await load()
        } catch { show(error); await inspectPending() }
    }

    private func load() async {
        do { connections = try await store.pluginConnections(); error = nil }
        catch { show(error) }
    }

    private func show(_ failure: Error) {
        if let api = failure as? APIError, api == .httpStatus(403) || api == .httpStatus(404) {
            error = String(localized: "plugin.unavailable")
        } else { error = failure.localizedDescription }
    }
}
