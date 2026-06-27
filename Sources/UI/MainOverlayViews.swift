import SwiftUI
import AppKit

public struct ContentView: View {
    @Environment(\.cubeStateManager) private var manager
    @AppStorage("sizeMode") private var sizeMode: SizeMode = .medium
    @AppStorage("anchorPosition") private var anchorPosition: Anchor = .topRight
    @State private var showSettings = false

    // Sync @AppStorage size mode into the manager so window resizes and state stays consistent
    private var sizeBinding: Binding<SizeMode> {
        Binding(
            get: { sizeMode },
            set: { newValue in
                sizeMode = newValue
                manager.setSizeMode(newValue)
            }
        )
    }

    // Sync anchor with persistence and notify manager/window
    private var anchorBinding: Binding<Anchor> {
        Binding(
            get: { anchorPosition },
            set: { newValue in
                anchorPosition = newValue
                manager.setAnchor(newValue)
            }
        )
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                header
                mainContent
            }
            .frame(width: manager.sizeMode.windowSize.width, height: manager.sizeMode.windowSize.height)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)

            settingsButton
        }
        .padding(8)
        .onReceive(NotificationCenter.default.publisher(for: .cubeStateDidChange)) { _ in
            // Triggers SwiftUI refresh when manager mutates from outside
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(manager.currentCase.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(manager.currentCase.caseType) \(manager.currentCase.caseNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: manager.randomCase) {
                Image(systemName: "shuffle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Random case")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var mainContent: some View {
        VStack(spacing: 12) {
            if manager.visualMode != .textOnly {
                CubeCanvasView(currentCase: manager.currentCase, visualMode: manager.visualMode)
                    .frame(height: manager.sizeMode == .compact ? 140 : 180)
                    .padding(.horizontal, 10)
            }

            if manager.visualMode != .setup {
                algorithmSection
            }

            controls
        }
        .padding(.bottom, 12)
    }

    private var algorithmSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Primary Algorithm")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)

            Text(manager.currentCase.primaryAlgorithm)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 14)

            if !manager.currentCase.alternativeAlgorithms.isEmpty {
                Text("Alternatives")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(manager.currentCase.alternativeAlgorithms.prefix(2)), id: \.self) { alt in
                        Text(alt)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: manager.previousCase) {
                Image(systemName: "arrow.left")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button(action: manager.nextCase) {
                Image(systemName: "arrow.right")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .popover(isPresented: $showSettings) {
                settingsPanel
                    .frame(width: 260)
                    .padding()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    private var settingsButton: some View {
        EmptyView() // popover attached to controls gear
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)

            Picker("Size", selection: sizeBinding) {
                ForEach(SizeMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Picker("Visual Mode", selection: Binding(
                get: { manager.visualMode },
                set: { manager.setVisualMode($0) }
            )) {
                ForEach(VisualMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.replacingOccurrences(of: "preExecution", with: "Pre-Exec")).tag(mode)
                }
            }

            Picker("Anchor", selection: anchorBinding) {
                ForEach(Anchor.allCases, id: \.self) { anchor in
                    Text(anchor.rawValue.replacingOccurrences(of: "topLeft", with: "Top Left").replacingOccurrences(of: "topRight", with: "Top Right").replacingOccurrences(of: "bottomLeft", with: "Bottom Left").replacingOccurrences(of: "bottomRight", with: "Bottom Right")).tag(anchor)
                }
            }

            Text("Changes apply live to the floating window.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

public struct CubeCanvasView: View {
    let currentCase: CubeCase
    let visualMode: VisualMode

    public var body: some View {
        Canvas { context, size in
            drawTopDownCube(context: context, size: size)
        }
        .background(Color.black.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func drawTopDownCube(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let face = min(w, h) * 0.82
        let s = face / 3
        let ox = (w - face) / 2
        let oy = (h - face) / 2 + 4

        let colors: [Color] = [
            .white, .yellow, .red, .orange, .blue, .green
        ]

        // Draw 3x3 grid representing top face (U) + front face hint
        for row in 0..<3 {
            for col in 0..<3 {
                let x = ox + CGFloat(col) * s
                let y = oy + CGFloat(row) * s
                let rect = CGRect(x: x + 1, y: y + 1, width: s - 2, height: s - 2)

                let stickerColor: Color
                if row == 1 && col == 1 {
                    stickerColor = .gray // center
                } else {
                    // Use deterministic color cycling based on case number
                    let idx = (currentCase.caseNumber + row * 3 + col) % colors.count
                    stickerColor = colors[idx]
                }

                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(stickerColor))
                context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.5)), lineWidth: 1)
            }
        }

        // Simple U-layer label
        context.draw(Text("U").font(.caption2.bold()), at: CGPoint(x: ox + face / 2, y: oy - 12))
    }
}
