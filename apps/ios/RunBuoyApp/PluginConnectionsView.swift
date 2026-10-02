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

struct PluginConnection: Decodable, Identifiable, Hashable, Sendable {
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var connections: [PluginConnection] = []
    @State private var request: PluginConnectionRequest?
    @State private var inspectedCode: PluginConnectionCode?
    @State private var presentedSheet: ConnectionSheet?
    @State private var selectedConnection: PluginConnection?
    @State private var busy = false
    @State private var refreshing = false
    @State private var refreshID: UUID?
    @State private var error: String?
    @State private var completion: String?
    @State private var revoking: PluginConnection?

    private enum ConnectionSheet: String, Identifiable {
        case scanner, link
        var id: String { rawValue }
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(colorScheme: colorScheme, reduceTransparency: reduceTransparency,
                     increasedContrast: contrast == .increased)
    }

    var body: some View {
        List {
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
            connectionsSection
            addConnectionSection
            workspaceSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.canvas)
        .runBuoyBottomScrollEdgeStyle()
        .navigationTitle("plugin.title")
        .accessibilityIdentifier("screen.agentConnections")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("plugin.reload", systemImage: "arrow.clockwise") {
                    Task { await load() }
                }
                .disabled(busy || refreshing)
                .accessibilityIdentifier("plugin.reload")
            }
        }
        .refreshable { await load() }
        .overlay { if busy { ProgressView().accessibilityLabel(Text("plugin.loading")) } }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .scanner:
                ScannerSheet { value in presentedSheet = nil; receive(value) }
            case .link:
                AgentConnectionLinkSheet { code in router.pendingPluginConnection = code }
            }
        }
        .navigationDestination(item: $selectedConnection) { connection in
            connectionDetails(connection)
        }
        .task { await load() }
        .task(id: router.pendingPluginConnection?.challenge) { await inspectPending() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await load(); await inspectPending() } }
        }
    }

    private var connectionsSection: some View {
        Section {
            if connections.isEmpty {
                Text("plugin.empty").runBuoySecondaryText()
            }
            ForEach(connections) { connection in
                Button {
                    selectedConnection = connection
                } label: {
                    HStack(spacing: 12) {
                        AgentConnectionIcon(clientName: connection.clientName)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(connection.clientName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(String(format: String(localized: "plugin.access_expiry"),
                                        connection.expiresAt.formatted(date: .abbreviated, time: .omitted)))
                                .font(.caption)
                                .runBuoySecondaryText()
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Circle()
                            .fill(theme.status(connection.expiresAt > .now ? .success : .neutral))
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .runBuoySecondaryText()
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(Text(connection.expiresAt > .now ? "plugin.connected" : "plugin.connection_expired"))
                .accessibilityHint(Text("plugin.details_hint"))
                .accessibilityIdentifier("plugin.connection.\(connection.id)")
            }
        } header: {
            Text("plugin.connected_agents").runBuoySecondaryText()
        } footer: {
            if connections.count == 1, let connection = connections.first {
                Text(String(format: String(localized: "plugin.connected_date"),
                            connection.createdAt.formatted(date: .abbreviated, time: .omitted)))
                    .runBuoySecondaryText()
            }
        }
        .listRowBackground(theme.surface)
    }

    private var addConnectionSection: some View {
        Section {
            Button { presentedSheet = .scanner } label: {
                connectionAction("plugin.scan", symbol: "qrcode.viewfinder")
            }
            .accessibilityIdentifier("plugin.scan")
            Button { presentedSheet = .link } label: {
                connectionAction("plugin.paste_action", symbol: "link")
            }
            .accessibilityIdentifier("plugin.pasteAction")
        } header: {
            Text("plugin.new").runBuoySecondaryText()
        } footer: {
            Text("plugin.review_hint").runBuoySecondaryText()
        }
        .disabled(busy)
        .listRowBackground(theme.surface)
    }

    private func connectionAction(_ title: LocalizedStringKey, symbol: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(title).foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .runBuoySecondaryText()
                .accessibilityHidden(true)
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var workspaceSection: some View {
        if let identity = store.deviceIdentity {
            Section {
                ShareLink(item: identity.workspaceID) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("plugin.workspace_id").font(.headline).foregroundStyle(.primary)
                            Text(identity.workspaceID)
                                .font(.caption.monospaced()).runBuoySecondaryText()
                                .lineLimit(1).truncationMode(.middle)
                                .accessibilityIdentifier("plugin.workspaceID")
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2).accessibilityHidden(true)
                    }
                    .frame(minHeight: 44)
                }
                .accessibilityLabel(Text("plugin.share_workspace"))
                .accessibilityValue(identity.workspaceID)
                .accessibilityIdentifier("plugin.shareWorkspace")
            } header: {
                Text("plugin.workspace").runBuoySecondaryText()
            } footer: {
                Text("plugin.footer").runBuoySecondaryText()
            }
            .listRowBackground(theme.surface)
        }
    }

    private func connectionDetails(_ connection: PluginConnection) -> some View {
        Form {
            Section {
                Label {
                    Text(connection.clientName).font(.headline)
                } icon: {
                    AgentConnectionIcon(clientName: connection.clientName)
                }
                Text("plugin.read_only").runBuoySecondaryText()
                LabeledContent("plugin.created") { Text(connection.createdAt, style: .date) }
                LabeledContent("plugin.expires") { Text(connection.expiresAt, style: .date) }
            }
            Section {
                Button("plugin.revoke", role: .destructive) { revoking = connection }
                    .disabled(busy).accessibilityIdentifier("plugin.revoke")
            } footer: { Text("plugin.revoke_effect") }
            if let error {
                Section { Label(error, systemImage: "exclamationmark.triangle") }
                    .foregroundStyle(.orange).accessibilityIdentifier("plugin.detailError")
            }
        }
        .navigationTitle("plugin.details")
        .navigationBarTitleDisplayMode(.inline)
        .runBuoyBottomScrollEdgeStyle()
        .accessibilityIdentifier("screen.agentConnectionDetails")
        .confirmationDialog("plugin.revoke_confirm", isPresented: Binding(
            get: { revoking != nil }, set: { if !$0 { revoking = nil } }
        ), titleVisibility: .visible) {
            if let connection = revoking {
                Button("plugin.revoke", role: .destructive) {
                    Task {
                        busy = true
                        defer { busy = false }
                        do {
                            try await store.revokePluginConnection(connection.id)
                            connections.removeAll { $0.id == connection.id }
                            selectedConnection = nil
                            await load()
                        }
                        catch { show(error) }
                    }
                }
                .accessibilityIdentifier("plugin.confirmRevoke")
            }
        } message: { Text("plugin.revoke_effect") }
    }

    private func consent(_ request: PluginConnectionRequest) -> some View {
        Section {
            Text(request.clientName).font(.title3.bold())
            LabeledContent("plugin.source", value: request.origin)
            LabeledContent("plugin.workspace", value: request.workspaceID).textSelection(.enabled)
                .accessibilityIdentifier("plugin.requestWorkspace")
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
        do { router.pendingPluginConnection = try PluginConnectionCode.decode(value) }
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
        let id = UUID()
        refreshID = id
        refreshing = true
        defer { if refreshID == id { refreshing = false } }
        do {
            let updated = try await store.pluginConnections()
            guard refreshID == id else { return }
            connections = updated
            error = nil
        } catch {
            guard refreshID == id else { return }
            show(error)
        }
    }

    private func show(_ failure: Error) {
        if let api = failure as? APIError, api == .httpStatus(403) || api == .httpStatus(404) {
            error = String(localized: "plugin.unavailable")
        } else { error = failure.localizedDescription }
    }
}

private struct AgentConnectionIcon: View {
    let clientName: String

    var body: some View {
        Group {
            if clientName.localizedCaseInsensitiveContains("chatgpt") {
                Image("AgentChatGPT")
                    .resizable().scaledToFit().frame(width: 34, height: 34)
                    .frame(width: 44, height: 44)
                    .background(.black, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "rectangle.connected.to.line.below")
                    .font(.title2).foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct AgentConnectionLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @State private var error: String?
    @FocusState private var focused: Bool
    let onReview: (PluginConnectionCode) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("plugin.paste", text: $link, axis: .vertical)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.URL).focused($focused)
                        .privacySensitive().accessibilityIdentifier("plugin.link")
                    Button("plugin.review") {
                        do {
                            let code = try PluginConnectionCode.decode(link)
                            onReview(code)
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                    .disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("plugin.review")
                } footer: { Text("plugin.review_hint") }
                if let error {
                    Section { Label(error, systemImage: "exclamationmark.triangle") }
                        .foregroundStyle(.orange).accessibilityIdentifier("plugin.linkError")
                }
            }
            .navigationTitle("plugin.paste_action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel", systemImage: "xmark") { dismiss() }
                }
            }
            .task { focused = true }
        }
    }
}
