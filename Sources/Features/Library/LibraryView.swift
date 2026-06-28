import SwiftUI
import AppKit

struct LibraryView: View {
    @State private var category: String = "F2L" // F2L | OLL | PLL | Learn
    @State private var searchText: String = ""
    @State private var selectedID: String?
    @State private var showFavoritesOnly: Bool = false

    @State private var favoriteCaseIDs: Set<String> = []
    @State private var myAlgorithms: [String: String] = [:]

    private let favKey = "favoriteCaseIDs"
    private let myAlgKey = "myAlgorithms"

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
            // Sidebar: list + search + filters
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
                            if myAlgorithms[c.id] != nil {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .tag(c.id)
                        .contextMenu {
                            Button(favoriteCaseIDs.contains(c.id) ? "Unfavorite" : "Favorite") {
                                toggleFavorite(c.id)
                            }
                            if myAlgorithms[c.id] != nil {
                                Button("Clear my alg") {
                                    myAlgorithms.removeValue(forKey: c.id)
                                    saveMyAlgs()
                                }
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
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(c.caseType) \(c.caseNumber) — \(c.name)")
                                .font(.title2.bold())

                            // Larger diagram
                            CubeStateView(currentCase: c, visualMode: .preExecution, sizeMode: .large)
                                .frame(width: 320, height: 260)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                            // Primary
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Primary").font(.headline)
                                    Spacer()
                                    Button {
                                        copyToClipboard(c.primaryAlgorithm)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .help("Copy primary algorithm")
                                }
                                Text(c.primaryAlgorithm)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                Text("\(moveCount(c.primaryAlgorithm)) moves")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            // My Algorithm (if set)
                            if let my = myAlgorithms[c.id] {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("My Algorithm").font(.headline)
                                        Spacer()
                                        Button {
                                            copyToClipboard(my)
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                        }
                                    }
                                    Text(my)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                    Text("\(moveCount(my)) moves")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // Alternatives
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Alternatives").font(.headline)
                                ForEach(c.alternativeAlgorithms, id: \.self) { alt in
                                    HStack(alignment: .top) {
                                        Text(alt)
                                            .font(.system(.body, design: .monospaced))
                                            .textSelection(.enabled)
                                        Text("(\(moveCount(alt)))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Button {
                                            copyToClipboard(alt)
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                        }
                                        .help("Copy")
                                        Button("Set as my alg") {
                                            setMyAlgorithm(for: c, alg: alt)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }

                            HStack {
                                Button(favoriteCaseIDs.contains(c.id) ? "★ Unfavorite" : "☆ Favorite") {
                                    toggleFavorite(c.id)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                    }
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

    private func moveCount(_ alg: String) -> Int {
        alg.split(separator: " ").filter { !$0.isEmpty }.count
    }

    private func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    private func toggleFavorite(_ id: String) {
        if favoriteCaseIDs.contains(id) {
            favoriteCaseIDs.remove(id)
        } else {
            favoriteCaseIDs.insert(id)
        }
        saveFavorites()
    }

    private func setMyAlgorithm(for c: CubeCase, alg: String) {
        myAlgorithms[c.id] = alg
        saveMyAlgs()
    }

    private func loadPersisted() {
        if let favs = UserDefaults.standard.stringArray(forKey: favKey) {
            favoriteCaseIDs = Set(favs)
        }
        if let data = UserDefaults.standard.data(forKey: myAlgKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            myAlgorithms = decoded
        }
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteCaseIDs), forKey: favKey)
    }

    private func saveMyAlgs() {
        if let data = try? JSONEncoder().encode(myAlgorithms) {
            UserDefaults.standard.set(data, forKey: myAlgKey)
        }
    }
}
