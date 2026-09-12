/// A disjoint partition of the already-filtered case list. Search must never
/// hide a match merely because it also appears in persisted navigation history.
struct CaseListSections {
    let pinned: [CubeCase]
    let recent: [CubeCase]
    let remaining: [CubeCase]

    static func remember(_ id: String, in history: [String]) -> [String] {
        var seen: Set<String> = []
        return Array(([id] + history).filter { seen.insert($0).inserted }.prefix(5))
    }

    init(cases: [CubeCase], recentIDs: [String], pinnedIDs: Set<String>, showHistory: Bool) {
        guard showHistory else {
            pinned = []
            recent = []
            remaining = cases
            return
        }
        pinned = cases.filter { pinnedIDs.contains($0.id) }
        var displayedIDs = Set(pinned.map(\.id))
        var recentCases: [CubeCase] = []
        for id in recentIDs {
            guard recentCases.count < 5 else { break }
            if !displayedIDs.contains(id), let cubeCase = cases.first(where: { $0.id == id }) {
                recentCases.append(cubeCase)
                displayedIDs.insert(id)
            }
        }
        recent = recentCases
        remaining = cases.filter { !displayedIDs.contains($0.id) }
    }
}
