import Foundation

public struct BeginnerStep: Identifiable, Equatable {
    public let id: Int
    public let title: String
    public let description: String
    public let algorithms: [String]
    public let linkTarget: String? // "F2L", "OLL", "PLL" or nil

    public init(id: Int, title: String, description: String, algorithms: [String], linkTarget: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.algorithms = algorithms
        self.linkTarget = linkTarget
    }
}

public struct BeginnerMethodDatabase {
    public static let steps: [BeginnerStep] = [
        BeginnerStep(
            id: 1,
            title: "White Cross",
            description: "Form a cross on the white face with all 4 edges aligned to their center colors. No set algorithm. Key tip: use the front face trick for misaligned edges.",
            algorithms: []
        ),
        BeginnerStep(
            id: 2,
            title: "White Corners",
            description: "Place all 4 white corners. Trigger: R U R' U' (or L' U' L U). Repeat until the corner drops in.",
            algorithms: ["R U R' U'", "L' U' L U"],
            linkTarget: "F2L"
        ),
        BeginnerStep(
            id: 3,
            title: "Middle Layer Edges",
            description: "Insert the 4 middle layer edges. Two triggers: Right insert and Left insert.",
            algorithms: ["U R U' R' U' F' U F", "U' L' U L U F U' F'"]
        ),
        BeginnerStep(
            id: 4,
            title: "Yellow Cross (OLL simplified)",
            description: "Get a yellow cross on top (ignoring corner orientation). Trigger: F R U R' U' F'. Apply 0–3 times.",
            algorithms: ["F R U R' U' F'"],
            linkTarget: "OLL"
        ),
        BeginnerStep(
            id: 5,
            title: "Orient Yellow Corners (OLL simplified)",
            description: "Orient all yellow corners using the Sune. Apply until all corners are oriented.",
            algorithms: ["R U R' U R U2 R'"],
            linkTarget: "OLL"
        ),
        BeginnerStep(
            id: 6,
            title: "Permute Yellow Corners (PLL simplified)",
            description: "Cycle 3 corners using the trigger. Repeat until corners are in the right positions (may need AUF first).",
            algorithms: ["U R U' L' U R' U' L"],
            linkTarget: "PLL"
        ),
        BeginnerStep(
            id: 7,
            title: "Permute Yellow Edges (PLL simplified)",
            description: "Cycle 3 edges using the trigger. One or two applications solves it.",
            algorithms: ["F2 U L R' F2 L' R U F2"],
            linkTarget: "PLL"
        )
    ]
}
