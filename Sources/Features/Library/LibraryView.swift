import SwiftUI
import AppKit

struct LibraryView: View {
    @State private var category: String = "F2L"
    @State private var searchText: String = ""
    @State private var selectedID: String?
    @State private var showFavoritesOnly: Bool = false

    @State private var favoriteCaseIDs: Set<String> = []
    @State private var customAlgorithms: [String: String] = [:]
    // Maps caseID → selected index. -1 = custom.
    @State private var selectedAlgIndices: [String: Int] = [:]

    private let favKey = UDKey.favoriteCaseIDs
    private let customAlgKey = UDKey.myAlgorithms
    private let selectionKey = UDKey.selectedAlgorithmIndices

    private var allCases: [CubeCase] {
        F2LDatabase.f2lCases + AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases
    }

    private var filteredCases: [CubeCase] {
        var base: [CubeCase]
        switch category {
        case "F2L": base = F2LDatabase.f2lCases
        case "OLL": base = AlgorithmDatabase.ollCases
        case "PLL": base = AlgorithmDatabase.pllCases
        default: base = []
        }

        if showFavoritesOnly {
            base = base.filter { favoriteCaseIDs.contains($0.id) }
        }

        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter { c in
            c.name.lowercased().contains(q) ||
            String(c.caseNumber).contains(q) ||
            c.primaryAlgorithm.lowercased().contains(q) ||
            c.alternativeAlgorithms.joined(separator: " ").lowercased().contains(q)
        }
    }

    private var selectedCase: CubeCase? {
        guard let id = selectedID else { return nil }
        return allCases.first { $0.id == id }
    }

    var body: some View {
        HSplitView {
            // Sidebar
            VStack(spacing: 8) {
                Picker("Category", selection: $category) {
                    Text("F2L").tag("F2L")
                    Text("OLL").tag("OLL")
                    Text("PLL").tag("PLL")
                    Text("Learn").tag("Learn")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 8)
                .onChange(of: category) { _, _ in
                    searchText = ""
                    selectedID = nil
                }

                if category != "Learn" {
                    Toggle("Favorites only", isOn: $showFavoritesOnly)
                        .font(.caption)
                        .padding(.horizontal, 8)

                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 8)

                    List(filteredCases, id: \.id, selection: $selectedID) { c in
                        HStack {
                            if favoriteCaseIDs.contains(c.id) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                            Text("\(c.caseNumber). \(c.name)")
                                .font(.system(size: 13))
                            Spacer()
                            if selectedAlgIndices[c.id] != nil || customAlgorithms[c.id] != nil {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                            }
                        }
                        .tag(c.id)
                        .contextMenu {
                            Button(favoriteCaseIDs.contains(c.id) ? "Unfavorite" : "Favorite") {
                                toggleFavorite(c.id)
                            }
                            Button("Reset to default alg") {
                                selectedAlgIndices.removeValue(forKey: c.id)
                                customAlgorithms.removeValue(forKey: c.id)
                                saveSelections()
                                saveCustomAlgs()
                            }
                        }
                    }
                    .listStyle(.sidebar)
                } else {
                    Text("Layer-by-Layer (Beginner)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }
            }
            .frame(minWidth: 240)

            // Detail pane
            VStack(alignment: .leading, spacing: 12) {
                if category == "Learn" {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(BeginnerMethodDatabase.steps) { step in
                                BeginnerStepView(step: step) { target in
                                    category = target
                                    searchText = ""
                                }
                            }
                            Button("Ready for more? Learn CFOP →") {
                                category = "F2L"
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                } else if let c = selectedCase {
                    CaseDetailView(
                        cubeCase: c,
                        selectedAlgIndex: binding(for: c.id),
                        customAlgorithm: customAlgBinding(for: c.id),
                        isFavorite: favoriteCaseIDs.contains(c.id),
                        onToggleFavorite: { toggleFavorite(c.id) },
                        onSelectionChanged: {
                            saveSelections()
                            saveCustomAlgs()
                        }
                    )
                } else {
                    VStack {
                        Spacer()
                        Text("Select a case from the list")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 520)
        }
        .onAppear(perform: loadPersisted)
    }

    // MARK: - Bindings

    private func binding(for id: String) -> Binding<Int?> {
        Binding(
            get: { selectedAlgIndices[id] },
            set: { selectedAlgIndices[id] = $0 }
        )
    }

    private func customAlgBinding(for id: String) -> Binding<String> {
        Binding(
            get: { customAlgorithms[id] ?? "" },
            set: { customAlgorithms[id] = $0.isEmpty ? nil : $0 }
        )
    }

    // MARK: - Persistence

    private func toggleFavorite(_ id: String) {
        if favoriteCaseIDs.contains(id) { favoriteCaseIDs.remove(id) }
        else { favoriteCaseIDs.insert(id) }
        UserDefaults.standard.set(Array(favoriteCaseIDs), forKey: favKey)
    }

    private func loadPersisted() {
        if let favs = UserDefaults.standard.stringArray(forKey: favKey) {
            favoriteCaseIDs = Set(favs)
        }
        if let data = UserDefaults.standard.data(forKey: customAlgKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            customAlgorithms = decoded
        }
        if let data = UserDefaults.standard.data(forKey: selectionKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            selectedAlgIndices = decoded
        }
    }

    private func saveSelections() {
        if let data = try? JSONEncoder().encode(selectedAlgIndices) {
            UserDefaults.standard.set(data, forKey: selectionKey)
        }
    }

    private func saveCustomAlgs() {
        let filtered = customAlgorithms.filter { !$0.value.isEmpty }
        if let data = try? JSONEncoder().encode(filtered) {
            UserDefaults.standard.set(data, forKey: customAlgKey)
        }
    }
}

// MARK: - Case Detail View

private struct CaseDetailView: View {
    let cubeCase: CubeCase
    @Binding var selectedAlgIndex: Int?   // nil = default (0), -1 = custom
    @Binding var customAlgorithm: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onSelectionChanged: () -> Void

    @State private var isEditingCustom = false
    @State private var draftCustom = ""

    private var allAlgorithms: [String] {
        [cubeCase.primaryAlgorithm] + cubeCase.alternativeAlgorithms
    }

    private var isCustomActive: Bool {
        selectedAlgIndex == -1 && !customAlgorithm.isEmpty
    }

    private var activeIndex: Int {
        let i = selectedAlgIndex ?? 0
        return (i < 0 || i >= allAlgorithms.count) ? 0 : i
    }

    private var activeAlgorithm: String {
        if isCustomActive { return customAlgorithm }
        return allAlgorithms[activeIndex]
    }

    private var activeLabel: String {
        if isCustomActive { return "Custom" }
        return activeIndex == 0 ? "Default" : "Alt \(activeIndex)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(cubeCase.caseType) \(cubeCase.caseNumber) — \(cubeCase.name)")
                            .font(.title2.bold())
                        if cubeCase.caseType == "PLL", let auf = cubeCase.auf,
                           !auf.isEmpty, auf != "none" {
                            Text("AUF: \(auf)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let tip = cubeCase.recognitionTip {
                            Text(tip)
                                .font(.caption.italic())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button(isFavorite ? "★ Unfavorite" : "☆ Favorite") {
                        onToggleFavorite()
                    }
                    .buttonStyle(.bordered)
                }

                AlgorithmPlaybackView(
                    cubeCase: cubeCase,
                    algorithm: activeAlgorithm,
                    visualMode: .preExecution,
                    sizeMode: .large
                )
                .id("\(cubeCase.id)|\(activeAlgorithm)")
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Active algorithm + dropdown picker
                algorithmPickerSection

                // Custom entry (shown only when custom is active or being edited)
                if isCustomActive || isEditingCustom {
                    customEntrySection
                }
            }
            .padding()
        }
    }

    // MARK: Algorithm picker

    @ViewBuilder
    private var algorithmPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Algorithm")
                .font(.headline)

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    if CaseDetailCopyPolicy.showsStandaloneNotation(
                        playbackShowsLiveNotation: (try? CubeEngine.parse(activeAlgorithm)) != nil
                    ) {
                        Text(activeAlgorithm)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    HStack(spacing: 8) {
                        Text(activeLabel)
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("\(moveCount(activeAlgorithm)) moves")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    copyToClipboard(activeAlgorithm)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .help("Copy")
                .accessibilityLabel("Copy algorithm")
            }
            .padding(12)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Dropdown to change
            HStack(spacing: 8) {
                Menu {
                    // Preset algorithms from the database
                    ForEach(Array(allAlgorithms.enumerated()), id: \.offset) { idx, alg in
                        Button {
                            selectedAlgIndex = idx
                            isEditingCustom = false
                            onSelectionChanged()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(idx == 0 ? "Default (recommended)" : "Alt \(idx)")
                                    Text(alg).foregroundStyle(.secondary)
                                }
                                if activeIndex == idx && !isCustomActive {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    // Custom entry
                    Button {
                        if customAlgorithm.isEmpty {
                            draftCustom = ""
                            isEditingCustom = true
                        } else {
                            selectedAlgIndex = -1
                            onSelectionChanged()
                        }
                    } label: {
                        HStack {
                            Text(customAlgorithm.isEmpty ? "Enter custom algorithm…" : "Custom: \(customAlgorithm)")
                            if isCustomActive {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    if isCustomActive {
                        Button("Edit custom algorithm…") {
                            draftCustom = customAlgorithm
                            isEditingCustom = true
                        }
                        Button("Clear custom algorithm", role: .destructive) {
                            customAlgorithm = ""
                            selectedAlgIndex = 0
                            isEditingCustom = false
                            onSelectionChanged()
                        }
                    }
                } label: {
                    Label("Change algorithm", systemImage: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: Custom algorithm text entry

    @ViewBuilder
    private var customEntrySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isEditingCustom ? "Enter custom algorithm" : "Custom algorithm")
                .font(.subheadline.weight(.medium))

            if isEditingCustom {
                HStack {
                    TextField("e.g. R U R' U' R' F R F'", text: $draftCustom)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button("Save") {
                        let t = draftCustom.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty {
                            customAlgorithm = t
                            selectedAlgIndex = -1
                        }
                        isEditingCustom = false
                        onSelectionChanged()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(draftCustom.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("Cancel") { isEditingCustom = false }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            } else {
                Text(customAlgorithm)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func moveCount(_ alg: String) -> String {
        guard let count = try? CubeEngine.sliceTurnCount(alg) else { return "—" }
        return String(count)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
