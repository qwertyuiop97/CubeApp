import SwiftUI
import AppKit

struct BeginnerStepView: View {
    let step: BeginnerStep
    let onNavigate: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(step.id). \(step.title)")
                    .font(.headline)
                Spacer()
                if let target = step.linkTarget {
                    Button("Go to \(target)") {
                        onNavigate(target)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Text(step.description)
                .font(.body)
                .foregroundStyle(.secondary)

            if !step.algorithms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(step.algorithms, id: \.self) { alg in
                        HStack {
                            Text(alg)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button {
                                let pb = NSPasteboard.general
                                pb.clearContents()
                                pb.setString(alg, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .help("Copy")
                        }
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
