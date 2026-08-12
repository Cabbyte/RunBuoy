import SwiftUI

private enum PairingStatus: Equatable {
    case success
    case invalidCode
    case failed

    var title: LocalizedStringKey {
        switch self {
        case .success:
            "pairing.success"
        case .invalidCode:
            "pairing.invalid_code_heading"
        case .failed:
            "pairing.failed"
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .success:
            "pairing.success"
        case .invalidCode:
            "pairing.invalid_code_description"
        case .failed:
            "pairing.failed_description"
        }
    }

    var symbol: String {
        self == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
}

struct PairMachineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RunBuoyStore.self) private var store
    @Environment(AppRouter.self) private var router

    let allowsCodeEntry: Bool

    @State private var code: PairingCode?
    @State private var rawCode = ""
    @State private var status: PairingStatus?
    @State private var isWorking = false
    @State private var showsScanner = false
    @State private var pairingTask: Task<Void, Never>?
    @FocusState private var isCodeFieldFocused: Bool

    init(
        initialCode: PairingCode? = nil,
        allowsCodeEntry: Bool = true,
        dismissesOnSuccess _: Bool = false
    ) {
        self.allowsCodeEntry = allowsCodeEntry
        _code = State(initialValue: initialCode)
    }

    var body: some View {
        ScrollView {
            Group {
                if isWorking, let code {
                    PairingWorkingContent(
                        machineName: code.machineDisplayName,
                        cancel: cancelPairing
                    )
                } else if let status, status != .success {
                    PairingFailureContent(
                        status: status,
                        retry: resetCode,
                        scan: { showsScanner = true }
                    )
                } else if let code {
                    PairingConfirmationContent(
                        code: code,
                        isWorking: isWorking,
                        confirm: claimPairing,
                        reset: resetCode
                    )
                } else if allowsCodeEntry {
                    PairingEntryContent(
                        rawCode: $rawCode,
                        isCodeFieldFocused: $isCodeFieldFocused,
                        confirm: validateCode,
                        scan: { showsScanner = true }
                    )
                } else {
                    PairingFailureContent(
                        status: .invalidCode,
                        retry: resetCode,
                        scan: { showsScanner = true }
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .background(Color(.systemGroupedBackground))
        .accessibilityIdentifier("screen.pairMachine")
        .navigationTitle("pairing.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showsScanner) {
            ScannerSheet(onCode: receiveScannedValue)
        }
        .onAppear {
            receivePendingPairingCode(router.pendingPairingCode)
        }
        .onChange(of: router.pendingPairingCode) { _, pendingCode in
            receivePendingPairingCode(pendingCode)
        }
        .onDisappear {
            pairingTask?.cancel()
        }
    }

    private var trimmedCode: String {
        rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validateCode() {
        do {
            let decoded = try PairingCode.decode(trimmedCode)
            try decoded.requireSelectedRegion()
            code = decoded
            status = nil
            isCodeFieldFocused = false
        } catch {
            status = .invalidCode
            isCodeFieldFocused = false
        }
    }

    private func resetCode() {
        pairingTask?.cancel()
        pairingTask = nil
        code = nil
        rawCode = ""
        status = nil
        isWorking = false
    }

    private func receiveScannedValue(_ value: String) {
        do {
            let decoded = try PairingCode.decode(value)
            try decoded.requireSelectedRegion()
            code = decoded
            status = nil
            rawCode = value
        } catch {
            code = nil
            status = .invalidCode
        }
    }

    private func receivePendingPairingCode(_ pendingCode: PairingCode?) {
        guard let pendingCode else { return }
        do {
            try pendingCode.requireSelectedRegion()
            code = pendingCode
            status = nil
            isCodeFieldFocused = false
        } catch {
            code = nil
            status = .invalidCode
        }
    }

    private func cancelPairing() {
        pairingTask?.cancel()
        pairingTask = nil
        isWorking = false
    }

    private func claimPairing() {
        guard let code, !isWorking else { return }
        status = nil
        isWorking = true
        pairingTask = Task {
            do {
                try await store.claim(code)
                guard !Task.isCancelled else { return }
                status = .success
                router.pendingPairingCode = nil
                dismiss()
            } catch {
                guard !Task.isCancelled else { return }
                status = .failed
            }
            isWorking = false
            pairingTask = nil
        }
    }
}

private struct PairingEntryContent: View {
    @Binding var rawCode: String
    let isCodeFieldFocused: FocusState<Bool>.Binding
    let confirm: () -> Void
    let scan: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PairingHero(
                symbol: "link",
                title: "pairing.connect_title",
                detail: "pairing.enter_code_description"
            )

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "keyboard")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    TextField("pairing.code_placeholder", text: $rawCode)
                        .font(.title2.weight(.semibold))
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.continue)
                        .focused(isCodeFieldFocused)
                        .onSubmit(confirm)
                        .accessibilityIdentifier("pairing.code")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(minHeight: 64)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))

                Button(action: scan) {
                    Label("pairing.scan_action", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .labelStyle(.titleAndIcon)
                .runBuoySecondaryButtonStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.accentColor)
                .accessibilityIdentifier("machines.scanPairingCode")

                Button(action: confirm) {
                    Label("pairing.confirm_action", systemImage: "link")
                        .frame(maxWidth: .infinity)
                }
                .labelStyle(.titleAndIcon)
                .runBuoyProminentButtonStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .disabled(rawCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("pairing.continue")

                Text("pairing.expiry_hint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 102)
        }
        .padding(.top, 42)
    }
}

private struct PairingConfirmationContent: View {
    let code: PairingCode
    let isWorking: Bool
    let confirm: () -> Void
    let reset: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PairingHero(
                symbol: "desktopcomputer",
                title: LocalizedStringKey(code.machineDisplayName),
                detail: "pairing.confirm_identity_description"
            )

            VStack(spacing: 14) {
                if let platform = code.platform {
                    Label(platform, systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: confirm) {
                    Label("pairing.confirm_action", systemImage: "link")
                        .frame(maxWidth: .infinity)
                }
                .labelStyle(.titleAndIcon)
                .runBuoyProminentButtonStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .disabled(isWorking)
                .accessibilityIdentifier("pairing.claim")

                Button("pairing.try_another_code", action: reset)
                    .runBuoySecondaryButtonStyle()
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.accentColor)
            }
            .padding(.top, 102)
        }
        .padding(.top, 70)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pairing.machineName")
    }
}

private struct PairingWorkingContent: View {
    let machineName: String
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PairingHero(
                symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                title: LocalizedStringKey(
                    String(format: String(localized: "pairing.working_title"), machineName)
                ),
                detail: "pairing.working_description"
            )

            ProgressView()
                .progressViewStyle(.linear)
                .frame(maxWidth: 280)
                .padding(.top, 74)

            Button("common.cancel", action: cancel)
                .frame(maxWidth: 280)
                .runBuoySecondaryButtonStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.accentColor)
                .padding(.top, 34)
        }
        .padding(.top, 170)
    }
}

private struct PairingFailureContent: View {
    let status: PairingStatus
    let retry: () -> Void
    let scan: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PairingHero(
                symbol: status.symbol,
                title: status.title,
                detail: status.detail
            )

            VStack(spacing: 14) {
                Button(action: retry) {
                    Label("pairing.try_another_code", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .labelStyle(.titleAndIcon)
                .runBuoyProminentButtonStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)

                Button(action: scan) {
                    Label("pairing.scan_instead", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .labelStyle(.titleAndIcon)
                .runBuoySecondaryButtonStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.accentColor)
                .accessibilityIdentifier("machines.scanPairingCode")
            }
            .padding(.top, 96)
        }
        .padding(.top, 100)
        .accessibilityIdentifier("pairing.status")
    }
}

private struct PairingHero: View {
    let symbol: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 72, height: 72)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24))
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
    }
}

#Preview("Enter Pairing Code") {
    NavigationStack {
        PairMachineView()
    }
    .environment(PreviewFixtures.store())
    .environment(AppRouter())
}

#Preview("Confirm Pairing") {
    NavigationStack {
        PairMachineView(
            initialCode: PairingCode(
                sessionID: "session_preview",
                challenge: "preview",
                machineDisplayName: "Mac Studio",
                platform: "macOS"
            )
        )
    }
    .environment(PreviewFixtures.store())
    .environment(AppRouter())
}
