#if DEBUG
import SwiftUI
import UIKit

/// A UI-test-only reproduction, isolated from Form, navigation and combined elements.
struct UITypographyProbe: View {
    private let usesUIKit = ProcessInfo.processInfo.arguments.contains("-runbuoy-probe-uikit")
    private let combinesText = ProcessInfo.processInfo.arguments.contains("-runbuoy-probe-combined")
    private let usesForm = ProcessInfo.processInfo.arguments.contains("-runbuoy-probe-form")
    private let addsRows = ProcessInfo.processInfo.arguments.contains("-runbuoy-probe-lower-row")

    var body: some View {
        if usesForm {
            NavigationStack {
                Form {
                    if addsRows {
                        ForEach(0..<6) { index in Text("Context row \(index + 1)") }
                    }
                    Text("Computer confirmation times are shown on each task.")
                        .font(.caption)
                        .accessibilityIdentifier("probe.hint")
                    NavigationLink {
                        Text("Paired machines")
                    } label: {
                        LabeledContent {
                            HStack(spacing: 4) {
                                Text("2").accessibilityIdentifier("probe.count")
                                Text("paired").accessibilityIdentifier("probe.suffix")
                            }
                        } label: {
                            Label {
                                Text("Machines").accessibilityIdentifier("probe.title")
                            } icon: {
                                Image(systemName: "desktopcomputer")
                            }
                        }
                    }
                }
                .navigationTitle("Typography probe")
            }
        } else if combinesText {
            labels.accessibilityElement(children: .combine)
        } else {
            labels
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 24) {
            if usesUIKit {
                ProbeLabel(text: "Computer confirmation times are shown on each task.", style: .caption1, identifier: "probe.hint")
                ProbeLabel(text: "Machines", style: .body, identifier: "probe.title")
                ProbeLabel(text: "2", style: .body, identifier: "probe.count")
                ProbeLabel(text: "paired", style: .body, identifier: "probe.suffix")
            } else {
                Text("Computer confirmation times are shown on each task.")
                    .font(.caption)
                    .accessibilityIdentifier("probe.hint")
                Text("Machines")
                    .font(.body)
                    .accessibilityIdentifier("probe.title")
                Text("2")
                    .font(.body)
                    .accessibilityIdentifier("probe.count")
                Text("paired")
                    .font(.body)
                    .accessibilityIdentifier("probe.suffix")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
    }
}

private struct ProbeLabel: UIViewRepresentable {
    let text: String
    let style: UIFont.TextStyle
    let identifier: String

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.text = text
        label.font = .preferredFont(forTextStyle: style, compatibleWith: label.traitCollection)
        label.accessibilityIdentifier = identifier
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        uiView.sizeThatFits(CGSize(width: proposal.width ?? 350, height: .greatestFiniteMagnitude))
    }
}
#endif
