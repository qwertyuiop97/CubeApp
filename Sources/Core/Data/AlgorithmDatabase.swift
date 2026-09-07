import Foundation

public struct CubeCase: Identifiable, Codable, Equatable {
    public var id: String { "\(caseType)-\(caseNumber)" }
    public let caseNumber: Int
    public let caseType: String // "OLL", "PLL", or "F2L"
    public let name: String
    public let primaryAlgorithm: String
    public let alternativeAlgorithms: [String]
    public let diagramImagePlaceholder: String
    public let auf: String?
    public let recognitionTip: String?

    public init(caseNumber: Int, caseType: String, name: String, primaryAlgorithm: String, alternativeAlgorithms: [String], diagramImagePlaceholder: String, auf: String? = nil, recognitionTip: String? = nil) {
        self.caseNumber = caseNumber
        self.caseType = caseType
        self.name = name
        self.primaryAlgorithm = primaryAlgorithm
        self.alternativeAlgorithms = alternativeAlgorithms
        self.diagramImagePlaceholder = diagramImagePlaceholder
        self.auf = auf
        self.recognitionTip = recognitionTip
    }
}

// Source: CubeSkills OLL/PLL sheets by Feliks Zemdegs & Andy Klise
public struct AlgorithmDatabase {
    public static let ollCases: [CubeCase] = [

        // MARK: No Edges Flipped (O-group)

        CubeCase(
            caseNumber: 1,
            caseType: "OLL",
            name: "Dot 1",
            primaryAlgorithm: "R U2' R2' F R F' U2' R' F R F'",
            alternativeAlgorithms: [
                "y' r' R U R U R' U' r2 R2' U R U' r'",
                "F R U R' U' F' y' f R U R' U' f'"
            ],
            diagramImagePlaceholder: "oll_1",
            recognitionTip: "Dot — only the center is yellow; solid yellow bars face right and left."
        ),
        CubeCase(
            caseNumber: 2,
            caseType: "OLL",
            name: "Dot 2",
            primaryAlgorithm: "F R U R' U' F' f R U R' U' f'",
            alternativeAlgorithms: [
                "y r U r' U2 R U2' R' U2 r U' r'",
                "f R U R' U' f' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_2",
            recognitionTip: "Dot — only the center is yellow; solid yellow bar faces left."
        ),
        CubeCase(
            caseNumber: 3,
            caseType: "OLL",
            name: "Dot 3",
            primaryAlgorithm: "f R U R' U' f' U' F R U R' U' F'",
            alternativeAlgorithms: [
                "y' f R U R' U' f' U' F R U R' U' F'",
                "r' R2 U R' U' r U2 r' U M'"
            ],
            diagramImagePlaceholder: "oll_3",
            recognitionTip: "Dot with the front-right corner yellow on top."
        ),
        CubeCase(
            caseNumber: 4,
            caseType: "OLL",
            name: "Dot 4",
            primaryAlgorithm: "f R U R' U' f' U F R U R' U' F'",
            alternativeAlgorithms: [
                "y' f R U R' U' f' U F R U R' U' F'",
                "r' U2 R U R' U r U F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_4",
            recognitionTip: "Dot with the back-right corner yellow on top."
        ),

        // MARK: Squares

        CubeCase(
            caseNumber: 5,
            caseType: "OLL",
            name: "Square 1",
            primaryAlgorithm: "r' U2' R U R' U r",
            alternativeAlgorithms: [
                "y2 l' U2 L U L' U l",
                "y' F R' F' R U2 R U2' R'"
            ],
            diagramImagePlaceholder: "oll_5",
            recognitionTip: "2x2 yellow square at front-right; yellow pairs face back and left."
        ),
        CubeCase(
            caseNumber: 6,
            caseType: "OLL",
            name: "Square 2",
            primaryAlgorithm: "r U2 R' U' R U' r'",
            alternativeAlgorithms: [
                "y2 l U2 L' U' L U' l'",
                "F R U R' U' F' U' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_6",
            recognitionTip: "2x2 yellow square at back-right; yellow pairs face front and left."
        ),

        // MARK: Lightning Bolts

        CubeCase(
            caseNumber: 7,
            caseType: "OLL",
            name: "Lightning 1",
            primaryAlgorithm: "r U R' U R U2' r'",
            alternativeAlgorithms: [
                "y2 l U L' U L U2' l'",
                "F R U R' U' R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_7",
            recognitionTip: "Lightning bolt — front-left corner up; yellow pairs hug the front-right edge."
        ),
        CubeCase(
            caseNumber: 8,
            caseType: "OLL",
            name: "Lightning 2",
            primaryAlgorithm: "r' U' R U' R' U2 r",
            alternativeAlgorithms: [
                "y2 l' U' L U' L' U2 l",
                "R U2' R' U' R U' R' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_8",
            recognitionTip: "Mirror lightning — back-left corner up; yellow pairs hug the back-right edge."
        ),

        // MARK: Fish Shapes

        CubeCase(
            caseNumber: 9,
            caseType: "OLL",
            name: "Fish 1",
            primaryAlgorithm: "R U R' U' R' F R2 U R' U' F'",
            alternativeAlgorithms: [
                "R' U' R y r U' r' U r U r'",
                "y' r U R' U' r' R U R U' R'"
            ],
            diagramImagePlaceholder: "oll_9",
            recognitionTip: "Fish — front-right corner up; yellow pair on the front-left."
        ),
        CubeCase(
            caseNumber: 10,
            caseType: "OLL",
            name: "Fish 2",
            primaryAlgorithm: "R U R' U R' F R F' R U2' R'",
            alternativeAlgorithms: [
                "R U R' y R' F R U' R' F' R",
                "y2 L U L' U L' B L B' L U2' L'"
            ],
            diagramImagePlaceholder: "oll_10",
            recognitionTip: "Fish — back-right corner up; one yellow edge faces right."
        ),

        // MARK: Lightning Bolts (continued)

        CubeCase(
            caseNumber: 11,
            caseType: "OLL",
            name: "Lightning 3",
            primaryAlgorithm: "r' R2 U R' U R U2 R' U M'",
            alternativeAlgorithms: [
                "y2 M' U2 R U R' U R U2 R' U M",
                "F' L' U' L U L' U' L U F"
            ],
            diagramImagePlaceholder: "oll_11",
            recognitionTip: "Lightning bolt — front-left corner up; one yellow edge faces left."
        ),
        CubeCase(
            caseNumber: 12,
            caseType: "OLL",
            name: "Lightning 4",
            primaryAlgorithm: "M' R' U' R U' R' U2 R U' M",
            alternativeAlgorithms: [
                "y F R U R' U' F' U F R U R' U' F'",
                "r U R' U R U2' r' r' U' R U' R' U2 r"
            ],
            diagramImagePlaceholder: "oll_12",
            recognitionTip: "Mirror lightning — back-left corner up; one yellow edge faces left."
        ),

        // MARK: Knight Move Shapes

        CubeCase(
            caseNumber: 13,
            caseType: "OLL",
            name: "Knight Move 1",
            primaryAlgorithm: "r U' r' U' r U r' y' R' U R",
            alternativeAlgorithms: [
                "F U R U' R2' F' R U R U' R'",
                "y' r U' r' U' r U r' y R U' R'"
            ],
            diagramImagePlaceholder: "oll_13",
            recognitionTip: "Knight move — front-right corner up; yellow pairs hug the right face."
        ),
        CubeCase(
            caseNumber: 14,
            caseType: "OLL",
            name: "Knight Move 2",
            primaryAlgorithm: "R' F R U R' F' R F U' F'",
            alternativeAlgorithms: [
                "y L' B' L U' L' B L B' U B",
                "y2 r' U r U r' U' r y R U R'"
            ],
            diagramImagePlaceholder: "oll_14",
            recognitionTip: "Knight move — front-right corner up; yellow pairs hug the left face."
        ),
        CubeCase(
            caseNumber: 15,
            caseType: "OLL",
            name: "Knight Move 3",
            primaryAlgorithm: "r' U' r R' U' R U r' U r",
            alternativeAlgorithms: [
                "y2 l' U' l L' U' L U l' U l",
                "y' R' F R2 U' R' U' R U R' F'"
            ],
            diagramImagePlaceholder: "oll_15",
            recognitionTip: "Knight move — front-right corner up; one yellow edge faces front."
        ),
        CubeCase(
            caseNumber: 16,
            caseType: "OLL",
            name: "Knight Move 4",
            primaryAlgorithm: "r U r' R U R' U' r U' r'",
            alternativeAlgorithms: [
                "y2 l U l' L U L' U' l U' l'",
                "y L F' L2 U L U L' U' L F"
            ],
            diagramImagePlaceholder: "oll_16",
            recognitionTip: "Knight move — back-right corner up; one yellow edge faces back."
        ),

        // MARK: No Edges Flipped (continued)

        CubeCase(
            caseNumber: 17,
            caseType: "OLL",
            name: "Dot 5",
            primaryAlgorithm: "R U R' U R' F R F' U2' R' F R F'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' U R U R' U' R' F R F'",
                "r U R' U R U2' r' r' U' R U' R' U2 r"
            ],
            diagramImagePlaceholder: "oll_17",
            recognitionTip: "Dot with two diagonal corners yellow (front-right and back-left)."
        ),
        CubeCase(
            caseNumber: 18,
            caseType: "OLL",
            name: "Dot 6",
            primaryAlgorithm: "y R U2' R2' F R F' U2' M' U R U' r'",
            alternativeAlgorithms: [
                "r U R' U R U2 r' r' U' R U' R' U2 r",
                "F R U R' U' F' U F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_18",
            recognitionTip: "Dot with both front corners yellow; solid yellow bar faces left."
        ),
        CubeCase(
            caseNumber: 19,
            caseType: "OLL",
            name: "Dot 7",
            primaryAlgorithm: "M U R U R' U' M' R' F R F'",
            alternativeAlgorithms: [
                "y2 M' U' R' U' R U M R' F R F'",
                "r' R2 B R' B' r U R U' R'"
            ],
            diagramImagePlaceholder: "oll_19",
            recognitionTip: "Dot with both back corners yellow."
        ),
        CubeCase(
            caseNumber: 20,
            caseType: "OLL",
            name: "Dot 8",
            primaryAlgorithm: "M U R U R' U' M2' U R U' r'",
            alternativeAlgorithms: [
                "r U R' U' M2' U R U' R' U' M'",
                "y M' U' M2' U' M2' U' M' U2' M2'"
            ],
            diagramImagePlaceholder: "oll_20",
            recognitionTip: "Dot with all four corners yellow and every edge flipped."
        ),

        // MARK: All Edges Correct (OCLL group)

        CubeCase(
            caseNumber: 21,
            caseType: "OLL",
            name: "All Edges 1",
            primaryAlgorithm: "R U2 R' U' R U R' U' R U' R'",
            alternativeAlgorithms: [
                "y R U R' U R U' R' U R U2' R'",
                "y' F R U R' U' R U R' U' R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_21",
            recognitionTip: "Two-gen Sune-like. One headlight faces you."
        ),
        CubeCase(
            caseNumber: 22,
            caseType: "OLL",
            name: "All Edges 2 (Pi)",
            primaryAlgorithm: "R U2' R2' U' R2 U' R2' U2' R",
            alternativeAlgorithms: [
                "y2 R' U2 R2 U R2' U R2 U2 R'",
                "f R U R' U' f' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_22",
            recognitionTip: "All corners flipped — no headlights anywhere."
        ),
        CubeCase(
            caseNumber: 23,
            caseType: "OLL",
            name: "All Edges 3 (U)",
            primaryAlgorithm: "R2 D R' U2 R D' R' U2 R'",
            alternativeAlgorithms: [
                "y2 R2' D' R U2 R' D R U2 R",
                "y' R U2' R' U' R U' R' y R' U2' R U R' U R"
            ],
            diagramImagePlaceholder: "oll_23",
            recognitionTip: "Headlights on back face only."
        ),
        CubeCase(
            caseNumber: 24,
            caseType: "OLL",
            name: "All Edges 4 (T)",
            primaryAlgorithm: "r U R' U' r' F R F'",
            alternativeAlgorithms: [
                "y R U R D R' U' R D' R2'",
                "y' L' U' L F L' U' L U L F' L'"
            ],
            diagramImagePlaceholder: "oll_24",
            recognitionTip: "Headlights on front, two flipped edge corners on back."
        ),
        CubeCase(
            caseNumber: 25,
            caseType: "OLL",
            name: "All Edges 5 (L)",
            primaryAlgorithm: "y F' r U R' U' r' F R",
            alternativeAlgorithms: [
                "x R' U R D' R' U' R D x'",
                "y' R' F R B' R' F' R B"
            ],
            diagramImagePlaceholder: "oll_25",
            recognitionTip: "Headlights diagonal — one on front, one on right."
        ),
        CubeCase(
            caseNumber: 26,
            caseType: "OLL",
            name: "Anti-Sune",
            primaryAlgorithm: "R U2 R' U' R U' R'",
            alternativeAlgorithms: [
                "y' R' U' R U' R' U2 R",
                "y L' U' L U' L' U2 L"
            ],
            diagramImagePlaceholder: "oll_26",
            recognitionTip: "One headlight faces you, on front-right."
        ),
        CubeCase(
            caseNumber: 27,
            caseType: "OLL",
            name: "Sune",
            primaryAlgorithm: "R U R' U R U2' R'",
            alternativeAlgorithms: [
                "y' R' U2' R U R' U R",
                "y L U L' U L U2' L'"
            ],
            diagramImagePlaceholder: "oll_27",
            recognitionTip: "One headlight faces you, on front-left."
        ),

        // MARK: Corners Correct, Edges Flipped

        CubeCase(
            caseNumber: 28,
            caseType: "OLL",
            name: "Edge Flip 1",
            primaryAlgorithm: "r U R' U' M U R U' R'",
            alternativeAlgorithms: [
                "y' M' U M U2 M' U M",
                "r' R B R B' r U R U' R'"
            ],
            diagramImagePlaceholder: "oll_28",
            recognitionTip: "Arrow pointing right. Three edges flipped."
        ),

        // MARK: Awkward Shapes

        CubeCase(
            caseNumber: 29,
            caseType: "OLL",
            name: "Awkward 1",
            primaryAlgorithm: "y R U R' U' R U' R' F' U' F R U R'",
            alternativeAlgorithms: [
                "M U R U R' U' R' F R F' M'",
                "y2 R U R' U' R U' R' F' U' F R U R'"
            ],
            diagramImagePlaceholder: "oll_29",
            recognitionTip: "Awkward — right pair of corners up; yellow pair on the front-left."
        ),
        CubeCase(
            caseNumber: 30,
            caseType: "OLL",
            name: "Awkward 2",
            primaryAlgorithm: "y' F U R U2 R' U' R U2 R' U' F'",
            alternativeAlgorithms: [
                "y' F R' F R2 U' R' U' R U R' F2",
                "y2 r' D' r U r' D r U' r U r'"
            ],
            diagramImagePlaceholder: "oll_30",
            recognitionTip: "Awkward — both front corners up; one yellow edge faces front."
        ),

        // MARK: P-Shapes

        CubeCase(
            caseNumber: 31,
            caseType: "OLL",
            name: "P-Shape 1",
            primaryAlgorithm: "R' U' F U R U' R' F' R",
            alternativeAlgorithms: [
                "y L' U' F' U L U' L' F L",
                "y2 S R U R' U' R' F R f'"
            ],
            diagramImagePlaceholder: "oll_31",
            recognitionTip: "P-shape — right pair of corners up; yellow pair on the front-left."
        ),
        CubeCase(
            caseNumber: 32,
            caseType: "OLL",
            name: "P-Shape 2",
            primaryAlgorithm: "R U B' U' R' U R B R'",
            alternativeAlgorithms: [
                "S R U R' U' R' F R f'",
                "y' L U B' U' L' U L B L'"
            ],
            diagramImagePlaceholder: "oll_32",
            recognitionTip: "P-shape — right pair of corners up; yellow pair on the back-right."
        ),

        // MARK: T-Shapes

        CubeCase(
            caseNumber: 33,
            caseType: "OLL",
            name: "T-Shape 1",
            primaryAlgorithm: "R U R' U' R' F R F'",
            alternativeAlgorithms: [
                "y2 L' U' L U L F' L' F",
                "y R' U' F U R U' R' F' R"
            ],
            diagramImagePlaceholder: "oll_33",
            recognitionTip: "T-shape on top — bar across back, two corners flipped front."
        ),

        // MARK: C-Shapes

        CubeCase(
            caseNumber: 34,
            caseType: "OLL",
            name: "C-Shape 1",
            primaryAlgorithm: "R U R2' U' R' F R U R U' F'",
            alternativeAlgorithms: [
                "y2 R' U' R' F R F' R U2 R'",
                "F R U R' U' R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_34",
            recognitionTip: "C-shape — front pair of corners up; yellow edges face front and back."
        ),

        // MARK: Fish Shapes (continued)

        CubeCase(
            caseNumber: 35,
            caseType: "OLL",
            name: "Fish 3",
            primaryAlgorithm: "R U2' R2' F R F' R U2' R'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' R U R' U R U2 R'",
                "y L U2 L2 F' L F L U2 L'"
            ],
            diagramImagePlaceholder: "oll_35",
            recognitionTip: "Fish with diagonal corners up (back-left and front-right); yellow edges face back and left."
        ),

        // MARK: W-Shapes

        CubeCase(
            caseNumber: 36,
            caseType: "OLL",
            name: "W-Shape 1",
            primaryAlgorithm: "R' U' R U' R' U R U l U' R' U x",
            alternativeAlgorithms: [
                "y2 R U R' F' R U R' U' R' F R U' R' F R F'",
                "y' R' U' R U' R' U R U y R U' R' F'"
            ],
            diagramImagePlaceholder: "oll_36",
            recognitionTip: "W-shape — diagonal corners up (back-left, front-right); yellow pair on the right."
        ),

        // MARK: Fish Shapes (continued)

        CubeCase(
            caseNumber: 37,
            caseType: "OLL",
            name: "Fish 4",
            primaryAlgorithm: "F R U' R' U' R U R' F'",
            alternativeAlgorithms: [
                "y2 F L U' L' U' L U L' F'",
                "R' U' F U R U' R' F' R"
            ],
            diagramImagePlaceholder: "oll_37",
            recognitionTip: "Fish with diagonal corners up; yellow pairs on front-left and back-right."
        ),

        // MARK: W-Shapes (continued)

        CubeCase(
            caseNumber: 38,
            caseType: "OLL",
            name: "W-Shape 2",
            primaryAlgorithm: "R U R' U R U' R' U' R' F R F'",
            alternativeAlgorithms: [
                "y R' U' R U' R' U R y' R U' R' F'",
                "y2 L' U' L U' L' U L U L F' L' F"
            ],
            diagramImagePlaceholder: "oll_38",
            recognitionTip: "W-shape — the other diagonal corners up; one yellow edge faces front."
        ),

        // MARK: Lightning Bolts (B5, B6)

        CubeCase(
            caseNumber: 39,
            caseType: "OLL",
            name: "Lightning 5",
            primaryAlgorithm: "L F' L' U' L U F U' L'",
            alternativeAlgorithms: [
                "F R U R' U' F' R' U' R U' R' U2 R",
                "y2 R' U' R U' R' U R y R U' R' F'"
            ],
            diagramImagePlaceholder: "oll_39",
            recognitionTip: "Big lightning — diagonal corners up (back-right, front-left); one yellow edge faces front."
        ),
        CubeCase(
            caseNumber: 40,
            caseType: "OLL",
            name: "Lightning 6",
            primaryAlgorithm: "R' F R U R' U' F' U R",
            alternativeAlgorithms: [
                "y L' B L U L' U' B' U L",
                "y2 F R U R' U' F' U' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_40",
            recognitionTip: "Big lightning — the other diagonal corners up; one yellow edge faces front."
        ),

        // MARK: Awkward Shapes (continued)

        CubeCase(
            caseNumber: 41,
            caseType: "OLL",
            name: "Awkward 3",
            primaryAlgorithm: "R U R' U R U2' R' F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 R U2 R' U' R U R' U' F R U R' U' F'",
                "y' R U' R' U2 R U y R U' R' U' F'"
            ],
            diagramImagePlaceholder: "oll_41",
            recognitionTip: "Awkward — both front corners up; yellow edges face front and right."
        ),
        CubeCase(
            caseNumber: 42,
            caseType: "OLL",
            name: "Awkward 4",
            primaryAlgorithm: "R' U' R U' R' U2 R F R U R' U' F'",
            alternativeAlgorithms: [
                "y R' F R F' R' F R F' R U R' U' R U R'",
                "y2 R' U2 R U R' U' R U F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_42",
            recognitionTip: "Awkward — both back corners up; yellow edges face right and back."
        ),

        // MARK: P-Shapes (continued)

        CubeCase(
            caseNumber: 43,
            caseType: "OLL",
            name: "P-Shape 3",
            primaryAlgorithm: "y R' U' F' U F R",
            alternativeAlgorithms: [
                "f' L' U' L U f",
                "y2 F U R U' R' F'"
            ],
            diagramImagePlaceholder: "oll_43",
            recognitionTip: "P-shape — back pair of corners up; full yellow bar faces front."
        ),
        CubeCase(
            caseNumber: 44,
            caseType: "OLL",
            name: "P-Shape 4",
            primaryAlgorithm: "f R U R' U' f'",
            alternativeAlgorithms: [
                "y2 F U R U' R' F'",
                "y' F' U' L' U L F"
            ],
            diagramImagePlaceholder: "oll_44",
            recognitionTip: "P-shape — front pair of corners up; full yellow bar faces left."
        ),

        // MARK: T-Shapes (continued)

        CubeCase(
            caseNumber: 45,
            caseType: "OLL",
            name: "T-Shape 2",
            primaryAlgorithm: "F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 F R U R' U' F'",
                "y L' U' L U F L' F' L"
            ],
            diagramImagePlaceholder: "oll_45",
            recognitionTip: "Bar across the front of the top layer."
        ),

        // MARK: C-Shapes (continued)

        CubeCase(
            caseNumber: 46,
            caseType: "OLL",
            name: "C-Shape 2",
            primaryAlgorithm: "R' U' R' F R F' U R",
            alternativeAlgorithms: [
                "y L' U' L' B L B' U L",
                "y2 R' U' R' F R F' R U R"
            ],
            diagramImagePlaceholder: "oll_46",
            recognitionTip: "C-shape — left pair of corners up; full yellow bar faces right."
        ),

        // MARK: L-Shapes

        CubeCase(
            caseNumber: 47,
            caseType: "OLL",
            name: "L-Shape 1",
            primaryAlgorithm: "F' L' U' L U L' U' L U F",
            alternativeAlgorithms: [
                "R' U' R' F R F' R' F R F' U R",
                "y2 F R U R' U' R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_47",
            recognitionTip: "L-shape — yellow L at back-right; no corners up."
        ),
        CubeCase(
            caseNumber: 48,
            caseType: "OLL",
            name: "L-Shape 2",
            primaryAlgorithm: "F R U R' U' R U R' U' F'",
            alternativeAlgorithms: [
                "y2 F' L' U' L U L' U' L U F",
                "r' U' R U r F' R' F"
            ],
            diagramImagePlaceholder: "oll_48",
            recognitionTip: "L-shape — yellow L at back-left; no corners up."
        ),
        CubeCase(
            caseNumber: 49,
            caseType: "OLL",
            name: "L-Shape 3",
            primaryAlgorithm: "r U' r2' U r2 U r2' U' r",
            alternativeAlgorithms: [
                "y R U2 R' U' R U' R' F R U R' U' F'",
                "y2 l' U l2 U' l2' U' l2 U l'"
            ],
            diagramImagePlaceholder: "oll_49",
            recognitionTip: "L-shape — like OLL 47 but with a full yellow bar facing left."
        ),
        CubeCase(
            caseNumber: 50,
            caseType: "OLL",
            name: "L-Shape 4",
            primaryAlgorithm: "r' U r2 U' r2' U' r2 U r'",
            alternativeAlgorithms: [
                "y' R U2 R' U' R U' R' F R U R' U' F'",
                "y2 l U' l2 U l2 U l2' U' l"
            ],
            diagramImagePlaceholder: "oll_50",
            recognitionTip: "L-shape — yellow L at front-right; two yellow corners face back-right."
        ),

        // MARK: I-Shapes

        CubeCase(
            caseNumber: 51,
            caseType: "OLL",
            name: "I-Shape 1",
            primaryAlgorithm: "f R U R' U' R U R' U' f'",
            alternativeAlgorithms: [
                "y2 F U R U' R' U R U' R' F'",
                "F R U R' U' F' U F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_51",
            recognitionTip: "I-shape — diagonal yellow line (back-right to front-left); yellow pairs on front-right and back-left."
        ),
        CubeCase(
            caseNumber: 52,
            caseType: "OLL",
            name: "I-Shape 2",
            primaryAlgorithm: "R' U' R U' R' U y' R' U R B",
            alternativeAlgorithms: [
                "R U R' U R U' y R U' R' F'",
                "y2 r U R' U' r' U R U' R' r U' r'"
            ],
            diagramImagePlaceholder: "oll_52",
            recognitionTip: "I-shape — same diagonal as OLL 51, but a full yellow bar faces back."
        ),

        // MARK: L-Shapes (continued)

        CubeCase(
            caseNumber: 53,
            caseType: "OLL",
            name: "L-Shape 5",
            primaryAlgorithm: "r' U' R U' R' U R U' R' U2 r",
            alternativeAlgorithms: [
                "y r' U2' R U R' U' R U R' U r",
                "y2 l' U' L U' L' U L U' L' U2 l"
            ],
            diagramImagePlaceholder: "oll_53",
            recognitionTip: "L-shape — yellow L at front-right with a bar facing left; one yellow edge faces back."
        ),
        CubeCase(
            caseNumber: 54,
            caseType: "OLL",
            name: "L-Shape 6",
            primaryAlgorithm: "r U R' U R U' R' U R U2' r'",
            alternativeAlgorithms: [
                "y' r U2 R' U' R U R' U' R U' r'",
                "y2 l U L' U L U' L' U L U2' l'"
            ],
            diagramImagePlaceholder: "oll_54",
            recognitionTip: "L-shape — twin of OLL 47 with a bar facing left; one yellow edge faces front."
        ),

        // MARK: I-Shapes (rare)

        CubeCase(
            caseNumber: 55,
            caseType: "OLL",
            name: "I-Shape 3",
            primaryAlgorithm: "y R' F R U R U' R2' F' R2 U' R' U R U R'",
            alternativeAlgorithms: [
                "R U R' U R U' y R U' R' F'",
                "y2 F R U R' U' F' y R' U2 R U R' U R"
            ],
            diagramImagePlaceholder: "oll_55",
            recognitionTip: "I-shape — diagonal yellow line with full yellow bars facing front and back."
        ),
        CubeCase(
            caseNumber: 56,
            caseType: "OLL",
            name: "I-Shape 4",
            primaryAlgorithm: "r' U' r U' R' U R U' R' U R r' U r",
            alternativeAlgorithms: [
                "y2 l' U' l U' L' U L U' L' U L l' U l",
                "F R U R' U' F' f R U R' U' f'"
            ],
            diagramImagePlaceholder: "oll_56",
            recognitionTip: "I-shape — diagonal yellow line; one yellow edge faces front, one faces back."
        ),

        // MARK: Corners Correct Edges Flipped (rare)

        CubeCase(
            caseNumber: 57,
            caseType: "OLL",
            name: "Edge Flip 2",
            primaryAlgorithm: "R U R' U' M' U R U' r'",
            alternativeAlgorithms: [
                "y L U L' U' M' U L U' l'",
                "y2 r U R' U' r' R U R U' R'"
            ],
            diagramImagePlaceholder: "oll_57",
            recognitionTip: "Headlights on front and back, edges flipped left and right."
        )
    ]

    public static let pllCases: [CubeCase] = [

        // MARK: Permutations of Corners Only

        CubeCase(
            caseNumber: 1,
            caseType: "PLL",
            name: "Aa-Perm",
            primaryAlgorithm: "x R' U R' D2 R U' R' D2 R2 x'",
            alternativeAlgorithms: [
                "y x' R2 D2 R' U' R D2 R' U R' x",
                "l' U R' D2 R U' R' D2 R2 x'"
            ],
            diagramImagePlaceholder: "pll_aa",
            auf: "U / U'",
            recognitionTip: "Headlights on left, bar on right"
        ),
        CubeCase(
            caseNumber: 2,
            caseType: "PLL",
            name: "Ab-Perm",
            primaryAlgorithm: "x R2' D2 R U R' D2 R U' R x'",
            alternativeAlgorithms: [
                "y x' R U' R D2 R' U R D2 R2' x",
                "l U' R D2 R' U R D2 R2' x'"
            ],
            diagramImagePlaceholder: "pll_ab",
            auf: "U / U'",
            recognitionTip: "Headlights on right, bar on left"
        ),
        CubeCase(
            caseNumber: 3,
            caseType: "PLL",
            name: "F-Perm",
            primaryAlgorithm: "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R",
            alternativeAlgorithms: [
                "y R' U2 R' U' y R' F' R2 U' R' U R' F R U' F",
                "y2 R U R' U' R' F R F' R U2 R' U' R U R' U' R' F R F'"
            ],
            diagramImagePlaceholder: "pll_f",
            auf: "U",
            recognitionTip: "Two bars opposite each other, headlights on side"
        ),
        CubeCase(
            caseNumber: 4,
            caseType: "PLL",
            name: "Ga-Perm",
            primaryAlgorithm: "R2 U R' U R' U' R U' R2 D U' R' U R D'",
            alternativeAlgorithms: [
                "R2 u R' U R' U' R u' R2 y' R' U R",
                "y' D' R' U' R U D R2' U R' U R U' R U' R2'"
            ],
            diagramImagePlaceholder: "pll_ga",
            auf: "none",
            recognitionTip: "Headlights on the left; 1x2 block on the front face."
        ),
        CubeCase(
            caseNumber: 5,
            caseType: "PLL",
            name: "Gb-Perm",
            primaryAlgorithm: "F' U' F R2 u R' U R U' R u' R2'",
            alternativeAlgorithms: [
                "y' R' U' y F R2 u R' U R U' R u' R2'",
                "y D R' U' R U D' R2 U R' U R U' R U' R2'"
            ],
            diagramImagePlaceholder: "pll_gb",
            auf: "none",
            recognitionTip: "Headlights on the back; 1x2 block on the front face."
        ),
        CubeCase(
            caseNumber: 6,
            caseType: "PLL",
            name: "Gc-Perm",
            primaryAlgorithm: "R2 U' R U' R U R' U R2 D' U R U' R' D",
            alternativeAlgorithms: [
                "y2 R2' F2 R U2' R U2' R' F R U R' U' R' F R2",
                "y2 R2 u' R U' R U R' u R2 y R U' R'"
            ],
            diagramImagePlaceholder: "pll_gc",
            auf: "none",
            recognitionTip: "Headlights on the left; 1x2 block on the back face."
        ),
        CubeCase(
            caseNumber: 7,
            caseType: "PLL",
            name: "Gd-Perm",
            primaryAlgorithm: "D' R U R' U' D R2 U' R U' R' U R' U R2",
            alternativeAlgorithms: [
                "R U R' y' R2 u' R U' R' U R' u R2",
                "y' R' U' y F' R2 u' R U' R' U R' u R2"
            ],
            diagramImagePlaceholder: "pll_gd",
            auf: "none",
            recognitionTip: "Headlights on the left; 1x2 block on the right face."
        ),
        CubeCase(
            caseNumber: 8,
            caseType: "PLL",
            name: "E-Perm",
            primaryAlgorithm: "x' R U' R' D R U R' D' R U R' D R U' R' D' x",
            alternativeAlgorithms: [
                "x' L' U L D' L' U' L D L' U' L D' L' U L D x",
                "y x' R U' R' D R U R' D' R U R' D R U' R' D' x"
            ],
            diagramImagePlaceholder: "pll_e",
            auf: "none",
            recognitionTip: "Diagonal corners swap on both sides"
        ),
        CubeCase(
            caseNumber: 9,
            caseType: "PLL",
            name: "H-Perm",
            primaryAlgorithm: "M2' U M2' U2 M2' U M2'",
            alternativeAlgorithms: [
                "y M2' U' M2' U2' M2' U' M2'",
                "R2 U2 R U2 R2 U2 R2 U2 R U2 R2"
            ],
            diagramImagePlaceholder: "pll_h",
            auf: "none",
            recognitionTip: "All four edges swap in pairs"
        ),
        CubeCase(
            caseNumber: 10,
            caseType: "PLL",
            name: "Ja-Perm",
            primaryAlgorithm: "R' U L' U2 R U' R' U2 R L",
            alternativeAlgorithms: [
                "y' L' U' L F L' U' L U L F' L2' U L",
                "x R2' F R F' R U2 r' U r U2' x'"
            ],
            diagramImagePlaceholder: "pll_ja",
            auf: "U'",
            recognitionTip: "Headlights on right, J-shape on left"
        ),
        CubeCase(
            caseNumber: 11,
            caseType: "PLL",
            name: "Jb-Perm",
            primaryAlgorithm: "R U R' F' R U R' U' R' F R2 U' R'",
            alternativeAlgorithms: [
                "y2 L U L' B' L U L' U' L' B L2 U' L'",
                "R U2 R' U' R U2' L' U R' U' L"
            ],
            diagramImagePlaceholder: "pll_jb",
            auf: "U'",
            recognitionTip: "Headlights on left, J-shape on right"
        ),
        CubeCase(
            caseNumber: 12,
            caseType: "PLL",
            name: "Na-Perm",
            primaryAlgorithm: "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'",
            alternativeAlgorithms: [
                "z U R' D R2 U' R D' U R' D R2 U' R D'",
                "R' U R U' R' F' U' F R U R' F R' F' R U' R"
            ],
            diagramImagePlaceholder: "pll_na",
            auf: "none",
            recognitionTip: "Diagonal swaps — no headlights anywhere"
        ),
        CubeCase(
            caseNumber: 13,
            caseType: "PLL",
            name: "Nb-Perm",
            primaryAlgorithm: "R' U R U' R' F' U' F R U R' F R' F' R U' R",
            alternativeAlgorithms: [
                "R' U L' U2 R U' L R' U L' U2 R U' L",
                "z U' R D' R2 U R' D U' R D' R2 U R' D"
            ],
            diagramImagePlaceholder: "pll_nb",
            auf: "none",
            recognitionTip: "Diagonal swaps — mirror of Na"
        ),
        CubeCase(
            caseNumber: 14,
            caseType: "PLL",
            name: "Ra-Perm",
            primaryAlgorithm: "R U' R' U' R U R D R' U' R D' R' U2 R'",
            alternativeAlgorithms: [
                "y' L U2 L' U2 L F' L' U' L U L F L2'",
                "R U R' F' R U2' R' U2' R' F R U R U2' R'"
            ],
            diagramImagePlaceholder: "pll_ra",
            auf: "U'",
            recognitionTip: "Bar on right, headlights on left and front"
        ),
        CubeCase(
            caseNumber: 15,
            caseType: "PLL",
            name: "Rb-Perm",
            primaryAlgorithm: "R' U2 R U2' R' F R U R' U' R' F' R2",
            alternativeAlgorithms: [
                "R' U2 R' D' R U' R' D R U R U' R' U' R",
                "y L' U L' d' L' U' L D L' U L D' L U2 L"
            ],
            diagramImagePlaceholder: "pll_rb",
            auf: "U'",
            recognitionTip: "Bar on left, headlights on right and front"
        ),
        CubeCase(
            caseNumber: 16,
            caseType: "PLL",
            name: "T-Perm",
            primaryAlgorithm: "R U R' U' R' F R2 U' R' U' R U R' F'",
            alternativeAlgorithms: [
                "y2 L U L' U' L' B L2 U' L' U' L U L' B'",
                "R U R' U' R' F R F' r U R' U' r' F R F'"
            ],
            diagramImagePlaceholder: "pll_t",
            auf: "none",
            recognitionTip: "Headlights on front, two opposite edges swap"
        ),
        CubeCase(
            caseNumber: 17,
            caseType: "PLL",
            name: "Ua-Perm",
            primaryAlgorithm: "R U' R U R U R U' R' U' R2",
            alternativeAlgorithms: [
                "y2 R' U R' U' R' U' R' U R U R2",
                "M2' U M' U2 M U M2'"
            ],
            diagramImagePlaceholder: "pll_ua",
            auf: "none",
            recognitionTip: "Counter-clockwise U cycle"
        ),
        CubeCase(
            caseNumber: 18,
            caseType: "PLL",
            name: "Ub-Perm",
            primaryAlgorithm: "R2 U R U R' U' R' U' R' U R'",
            alternativeAlgorithms: [
                "y2 R' U R' U' R' U' R' U R U R2'",
                "M2' U' M' U2 M U' M2'"
            ],
            diagramImagePlaceholder: "pll_ub",
            auf: "none",
            recognitionTip: "Clockwise U cycle"
        ),
        CubeCase(
            caseNumber: 19,
            caseType: "PLL",
            name: "V-Perm",
            primaryAlgorithm: "R' U R' U' y R' F' R2 U' R' U R' F R F",
            alternativeAlgorithms: [
                "y R U' R U' R U' R U R' U R2 D' R U' R' D R2",
                "y2 R' U R' U' R' U' R' U R U R2 F' R U R' U' F"
            ],
            diagramImagePlaceholder: "pll_v",
            auf: "none",
            recognitionTip: "No matching stickers anywhere"
        ),
        CubeCase(
            caseNumber: 20,
            caseType: "PLL",
            name: "Y-Perm",
            primaryAlgorithm: "F R U' R' U' R U R' F' R U R' U' R' F R F'",
            alternativeAlgorithms: [
                "y2 F' L' U L U L' U' L F L' U' L U L F' L' F",
                "f R U' R' U' R U R' f' R U R' U' R' F R F'"
            ],
            diagramImagePlaceholder: "pll_y",
            auf: "none",
            recognitionTip: "No matching stickers — all diagonal swaps"
        ),
        CubeCase(
            caseNumber: 21,
            caseType: "PLL",
            name: "Z-Perm",
            primaryAlgorithm: "M2' U M2' U M' U2 M2' U2 M'",
            alternativeAlgorithms: [
                "y' M' U M2' U M2' U M' U2 M2",
                "y' R' U' R U' R U R U' R' U R U R2 U' R'"
            ],
            diagramImagePlaceholder: "pll_z",
            auf: "none",
            recognitionTip: "Adjacent edges swap on front and back"
        )
    ]
}
