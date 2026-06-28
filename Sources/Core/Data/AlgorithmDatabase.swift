import Foundation

public struct CubeCase: Identifiable, Codable, Equatable {
    public var id: String { "\(caseType)-\(caseNumber)" }
    public let caseNumber: Int
    public let caseType: String // "OLL", "PLL", or "F2L"
    public let name: String
    public let primaryAlgorithm: String
    public let alternativeAlgorithms: [String]
    public let diagramImagePlaceholder: String
    public let auf: String?           // e.g. "U", "U'", "U2", or nil
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

public struct AlgorithmDatabase {
    public static let ollCases: [CubeCase] = [
        // --- Group 1: All 57 OLL Cases ---
        CubeCase(
            caseNumber: 1,
            caseType: "OLL",
            name: "Runway",
            primaryAlgorithm: "R U2 R2 F R F' U2 R' F R F'",
            alternativeAlgorithms: [
                "y' r' R U R U R' U' r2 R2' U R U' r'",
                "F R U R' U' F' y' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_1"
        ),
        CubeCase(
            caseNumber: 2,
            caseType: "OLL",
            name: "Zamboni",
            primaryAlgorithm: "r U r' U2 r U2' r' U2 r U' r'",
            alternativeAlgorithms: [
                "F R U R' U' F' U f R U R' U' f'",
                "y' F R U R' U' F' y L' U' L U y' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_2"
        ),
        CubeCase(
            caseNumber: 3,
            caseType: "OLL",
            name: "Antispin",
            primaryAlgorithm: "f R U R' U' f' U' F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' U' y' f R U R' U' f'",
                "r' R2 U R' U r U2 r' U M'"
            ],
            diagramImagePlaceholder: "oll_3"
        ),
        CubeCase(
            caseNumber: 4,
            caseType: "OLL",
            name: "Spin",
            primaryAlgorithm: "f R U R' U' f' U F R U R' U' F'",
            alternativeAlgorithms: [
                "y' F U R U' R' F' U F R U R' U' F'",
                "r' R U R U R' U' M' U' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_4"
        ),
        CubeCase(
            caseNumber: 5,
            caseType: "OLL",
            name: "Bullwinkle",
            primaryAlgorithm: "r' U2 R U R' U r",
            alternativeAlgorithms: [
                "y2 l' U2 L U L' U l",
                "y' F R' F' R U2 R U2' R'"
            ],
            diagramImagePlaceholder: "oll_5"
        ),
        CubeCase(
            caseNumber: 6,
            caseType: "OLL",
            name: "Mona Lisa",
            primaryAlgorithm: "r U2 R' U' R U' r'",
            alternativeAlgorithms: [
                "y2 l U2 L' U' L U' l'",
                "F R U R' U' F' U' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_6"
        ),
        CubeCase(
            caseNumber: 7,
            caseType: "OLL",
            name: "Spelling Bee",
            primaryAlgorithm: "r U R' U R U2 r'",
            alternativeAlgorithms: [
                "y2 l U L' U L U2 l'",
                "F R U R' U' F' r U R' U' r'"
            ],
            diagramImagePlaceholder: "oll_7"
        ),
        CubeCase(
            caseNumber: 8,
            caseType: "OLL",
            name: "Kite",
            primaryAlgorithm: "r' U' R U' R' U2 r",
            alternativeAlgorithms: [
                "y2 l' U' L U' L' U2 l",
                "R U2 R' U' R U' R' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_8"
        ),
        CubeCase(
            caseNumber: 9,
            caseType: "OLL",
            name: "Kite Variant",
            primaryAlgorithm: "R U R' U' R' F R2 U R' U' F'",
            alternativeAlgorithms: [
                "y' R U R' U' R' F R F' R U2 R'",
                "R' U' R' F R F' U R"
            ],
            diagramImagePlaceholder: "oll_9"
        ),
        CubeCase(
            caseNumber: 10,
            caseType: "OLL",
            name: "Crest",
            primaryAlgorithm: "R U R' U R' F R F' R U2 R'",
            alternativeAlgorithms: [
                "y L U L' U L' B L B' L U2 L'",
                "R U R' U' R' F R2 U R' U' F' R U R' U' R' F R F'"
            ],
            diagramImagePlaceholder: "oll_10"
        ),
        CubeCase(
            caseNumber: 11,
            caseType: "OLL",
            name: "Dogbone",
            primaryAlgorithm: "r U R' U R U' R' U R U2' r'",
            alternativeAlgorithms: [
                "y2 M' U2 R U R' U R U2 R' U M",
                "F' L' U' L U L' U' L U F"
            ],
            diagramImagePlaceholder: "oll_11"
        ),
        CubeCase(
            caseNumber: 12,
            caseType: "OLL",
            name: "Dogbone Variant",
            primaryAlgorithm: "M' U2 R U R' U R U2' R' U M",
            alternativeAlgorithms: [
                "y2 F R U R' U' R U R' U' F'",
                "r U R' U R U2 r' U' r U R' U' r'"
            ],
            diagramImagePlaceholder: "oll_12"
        ),
        CubeCase(
            caseNumber: 13,
            caseType: "OLL",
            name: "Gun",
            primaryAlgorithm: "F U R U' R2' F' R U R U' R'",
            alternativeAlgorithms: [
                "y r U' r' U' r U r' y' R' U R",
                "y' R U' R' U' R U R' F' U F"
            ],
            diagramImagePlaceholder: "oll_13"
        ),
        CubeCase(
            caseNumber: 14,
            caseType: "OLL",
            name: "Gun Variant",
            primaryAlgorithm: "R' F R U R' F' R y' R U' R'",
            alternativeAlgorithms: [
                "y L' B' L U' L' B L y R U R'",
                "y2 r' U r U r' U' r y R U' R'"
            ],
            diagramImagePlaceholder: "oll_14"
        ),
        CubeCase(
            caseNumber: 15,
            caseType: "OLL",
            name: "Squeegee",
            primaryAlgorithm: "r' U' r R' U' R U r' U r",
            alternativeAlgorithms: [
                "y' R' F R2 U' R' U' R U R' F'",
                "y2 l' U' l L' U' L U l' U l"
            ],
            diagramImagePlaceholder: "oll_15"
        ),
        CubeCase(
            caseNumber: 16,
            caseType: "OLL",
            name: "Squeegee Variant",
            primaryAlgorithm: "r U r' R U R' U' r U' r'",
            alternativeAlgorithms: [
                "y L F' L2 U L U L' U' L F",
                "y2 l U l' L U L' U' l U' l'"
            ],
            diagramImagePlaceholder: "oll_16"
        ),
        CubeCase(
            caseNumber: 17,
            caseType: "OLL",
            name: "Diagonal",
            primaryAlgorithm: "F R U R' U' F' R U R' U' R' F R F'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' U R U R' U' R' F R F'",
                "r U R' U R U2' r' r' U' R U' R' U2 r"
            ],
            diagramImagePlaceholder: "oll_17"
        ),
        CubeCase(
            caseNumber: 18,
            caseType: "OLL",
            name: "Crown",
            primaryAlgorithm: "F R U R' U' F' U F R U R' U' F'",
            alternativeAlgorithms: [
                "y r U R' U R U2' r' U F R U R' U' F'",
                "y2 f R U R' U' f' U' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_18"
        ),
        CubeCase(
            caseNumber: 19,
            caseType: "OLL",
            name: "Bunny",
            primaryAlgorithm: "r' U2 R U R' U' R U R' U r",
            alternativeAlgorithms: [
                "M U R U R' U' M' R' F R F'",
                "y2 l' U2 L U L' U' L U L' U l"
            ],
            diagramImagePlaceholder: "oll_19"
        ),
        CubeCase(
            caseNumber: 20,
            caseType: "OLL",
            name: "X-case",
            primaryAlgorithm: "r U R' U' M2' U R U' r'",
            alternativeAlgorithms: [
                "y2 r U R' U' M U R U' r' M",
                "r' R U R U R' U' M2' U R U' r'"
            ],
            diagramImagePlaceholder: "oll_20"
        ),
        CubeCase(
            caseNumber: 21,
            caseType: "OLL",
            name: "Cross H",
            primaryAlgorithm: "R U2 R' U' R U R' U' R U' R'",
            alternativeAlgorithms: [
                "y F R U R' U' R U R' U' R U R' U' F'",
                "R U2' R2' U' R2 U' R2' U2' R"
            ],
            diagramImagePlaceholder: "oll_21"
        ),
        CubeCase(
            caseNumber: 22,
            caseType: "OLL",
            name: "Cross Pi",
            primaryAlgorithm: "R U2' R2' U' R2 U' R2' U2' R",
            alternativeAlgorithms: [
                "y R' U2 R2 U R2' U R2 U2 R'",
                "f R U R' U' f' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_22"
        ),
        CubeCase(
            caseNumber: 23,
            caseType: "OLL",
            name: "Cross U",
            primaryAlgorithm: "R2 D R' U2 R D' R' U2 R'",
            alternativeAlgorithms: [
                "y2 R2' D' R U2 R' D R U2 R",
                "y' R U2' R' U' R U' R' y R' U2' R U R' U R"
            ],
            diagramImagePlaceholder: "oll_23"
        ),
        CubeCase(
            caseNumber: 24,
            caseType: "OLL",
            name: "Cross T",
            primaryAlgorithm: "r U R' U' r' F R F'",
            alternativeAlgorithms: [
                "y F R' F' r U R U' r'",
                "y2 L' U' L U L F' L' F"
            ],
            diagramImagePlaceholder: "oll_24"
        ),
        CubeCase(
            caseNumber: 25,
            caseType: "OLL",
            name: "Cross L",
            primaryAlgorithm: "F' r U R' U' r' F R",
            alternativeAlgorithms: [
                "y' R' F R B' R' F' R B",
                "y2 l' U' L U l F' L' F"
            ],
            diagramImagePlaceholder: "oll_25"
        ),
        CubeCase(
            caseNumber: 26,
            caseType: "OLL",
            name: "Anti-Sune",
            primaryAlgorithm: "R U2' R' U' R U' R'",
            alternativeAlgorithms: [
                "y2 R' U' R U' R' U2 R",
                "y L' U' L U' L' U2 L"
            ],
            diagramImagePlaceholder: "oll_26"
        ),
        CubeCase(
            caseNumber: 27,
            caseType: "OLL",
            name: "Sune",
            primaryAlgorithm: "R U R' U R U2' R'",
            alternativeAlgorithms: [
                "y2 R' U2 R U R' U R",
                "L U L' U L U2 L'"
            ],
            diagramImagePlaceholder: "oll_27"
        ),
        CubeCase(
            caseNumber: 28,
            caseType: "OLL",
            name: "Arrow",
            primaryAlgorithm: "r U R' U' M U R U' R'",
            alternativeAlgorithms: [
                "y' M' U M U2 M' U M",
                "y2 r' U' R U M' U' R' U R"
            ],
            diagramImagePlaceholder: "oll_28"
        ),
        CubeCase(
            caseNumber: 29,
            caseType: "OLL",
            name: "Arrow Variant",
            primaryAlgorithm: "M U R U R' U' M' R' F R F'",
            alternativeAlgorithms: [
                "y2 R U R' U' R U' R' F' U' F R U R'",
                "y' M U' R U R' U' M' R' F R F'"
            ],
            diagramImagePlaceholder: "oll_29"
        ),
        CubeCase(
            caseNumber: 30,
            caseType: "OLL",
            name: "Antispin Variant",
            primaryAlgorithm: "r' D' r U r' D r U' r U r'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' U' F R U R' U' F'",
                "R2 U' R' F R' F' R U* R2"
            ],
            diagramImagePlaceholder: "oll_30"
        ),
        CubeCase(
            caseNumber: 31,
            caseType: "OLL",
            name: "Couch",
            primaryAlgorithm: "S R U R' U' R' F R f'",
            alternativeAlgorithms: [
                "y L' U' L U L F' L' F S'",
                "R' U' F U R U' R' F' R"
            ],
            diagramImagePlaceholder: "oll_31"
        ),
        CubeCase(
            caseNumber: 32,
            caseType: "OLL",
            name: "Couch Variant",
            primaryAlgorithm: "S R' U' R U R F' R' f",
            alternativeAlgorithms: [
                "y' L U L' U' L' B L B'",
                "R U B' U' R' U R B R'"
            ],
            diagramImagePlaceholder: "oll_32"
        ),
        CubeCase(
            caseNumber: 33,
            caseType: "OLL",
            name: "T-case 1",
            primaryAlgorithm: "R U R' U' R' F R F'",
            alternativeAlgorithms: [
                "y2 L' U' L U L F' L' F",
                "y R' U' F U R U' R' F' R"
            ],
            diagramImagePlaceholder: "oll_33"
        ),
        CubeCase(
            caseNumber: 34,
            caseType: "OLL",
            name: "T-case 2",
            primaryAlgorithm: "R U R' U' B' R' F R F' B",
            alternativeAlgorithms: [
                "y2 R' U' R U R B' R' B",
                "F R U R' U' F' U R U R' U' R' F R F'"
            ],
            diagramImagePlaceholder: "oll_34"
        ),
        CubeCase(
            caseNumber: 35,
            caseType: "OLL",
            name: "Fish 1",
            primaryAlgorithm: "R U2' R2' F R F' R U2' R'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' R U R' U R U2 R'",
                "y L U2 L2 F' L F L U2 L'"
            ],
            diagramImagePlaceholder: "oll_35"
        ),
        CubeCase(
            caseNumber: 36,
            caseType: "OLL",
            name: "Fish 2",
            primaryAlgorithm: "R' U' R U' R' U F' U F R",
            alternativeAlgorithms: [
                "y L' U' L U' L' U B' U B L",
                "R' U' R' F R F' R U2 R'"
            ],
            diagramImagePlaceholder: "oll_36"
        ),
        CubeCase(
            caseNumber: 37,
            caseType: "OLL",
            name: "Fish 3",
            primaryAlgorithm: "F R U' R' U' R U R' F'",
            alternativeAlgorithms: [
                "y2 F L U' L' U' L U L' F'",
                "R' U' F U R U' R' F' R"
            ],
            diagramImagePlaceholder: "oll_37"
        ),
        CubeCase(
            caseNumber: 38,
            caseType: "OLL",
            name: "Fish 4",
            primaryAlgorithm: "R U R' U R U' R' U' R' F R F'",
            alternativeAlgorithms: [
                "y F R U' R' U R U R' F'",
                "y2 R U2 R' U' R U' R' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_38"
        ),
        CubeCase(
            caseNumber: 39,
            caseType: "OLL",
            name: "Line/Spaghetti 1",
            primaryAlgorithm: "f R U R' U' f' F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' U F R U R' U' F'",
                "R U B' U' R' U R B R'"
            ],
            diagramImagePlaceholder: "oll_39"
        ),
        CubeCase(
            caseNumber: 40,
            caseType: "OLL",
            name: "Line/Spaghetti 2",
            primaryAlgorithm: "f R U R' U' f' U' F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' U' f R U R' U' f'",
                "R' U' R' F R F' R U2 R'"
            ],
            diagramImagePlaceholder: "oll_40"
        ),
        CubeCase(
            caseNumber: 41,
            caseType: "OLL",
            name: "Line/Spaghetti 3",
            primaryAlgorithm: "R U R' U R U2' R' F R U R' U' F'",
            alternativeAlgorithms: [
                "y' R U' R' U2 R U y R U' R' U' F'",
                "y2 R U2 R' U' R U R' U' F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_41"
        ),
        CubeCase(
            caseNumber: 42,
            caseType: "OLL",
            name: "Line/Spaghetti 4",
            primaryAlgorithm: "R' U' R U' R' U2 R F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 R' U2 R U R' U' R U F R U R' U' F'",
                "y L' U' L U' L' U2 L F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_42"
        ),
        CubeCase(
            caseNumber: 43,
            caseType: "OLL",
            name: "Awning",
            primaryAlgorithm: "f' L' U' L U f",
            alternativeAlgorithms: [
                "y' F' U' L' U L F",
                "y2 F U R U' R' F'"
            ],
            diagramImagePlaceholder: "oll_43"
        ),
        CubeCase(
            caseNumber: 44,
            caseType: "OLL",
            name: "Awning Variant",
            primaryAlgorithm: "f R U R' U' f'",
            alternativeAlgorithms: [
                "y' F U R U' R' F'",
                "y2 f R U R' U' S"
            ],
            diagramImagePlaceholder: "oll_44"
        ),
        CubeCase(
            caseNumber: 45,
            caseType: "OLL",
            name: "T-case 3",
            primaryAlgorithm: "F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 F R U R' U' F'",
                "y L' U' L U F L' F' L"
            ],
            diagramImagePlaceholder: "oll_45"
        ),
        CubeCase(
            caseNumber: 46,
            caseType: "OLL",
            name: "T-case 4",
            primaryAlgorithm: "R' U' R' F R F' U R",
            alternativeAlgorithms: [
                "y L' U' L' B L B' U L",
                "y2 R' U' R' F R F' R U R"
            ],
            diagramImagePlaceholder: "oll_46"
        ),
        CubeCase(
            caseNumber: 47,
            caseType: "OLL",
            name: "Break-in-the-wall",
            primaryAlgorithm: "F' L' U' L U L' U' L U F",
            alternativeAlgorithms: [
                "y2 F R U R' U' R U R' U' F'",
                "r U R' U' r' F R F' y R U R'"
            ],
            diagramImagePlaceholder: "oll_47"
        ),
        CubeCase(
            caseNumber: 48,
            caseType: "OLL",
            name: "Break-in-the-wall Variant",
            primaryAlgorithm: "F R U R' U' R U R' U' F'",
            alternativeAlgorithms: [
                "y2 F' L' U' L U L' U' L U F",
                "r' U' R U r F' R' F"
            ],
            diagramImagePlaceholder: "oll_48"
        ),
        CubeCase(
            caseNumber: 49,
            caseType: "OLL",
            name: "W-case 1",
            primaryAlgorithm: "R U R' U R U' R' U' F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 L U L' U L U' L' U' B' L' U' L U B",
                "y' r U R' U R U2' r' y' R' U R"
            ],
            diagramImagePlaceholder: "oll_49"
        ),
        CubeCase(
            caseNumber: 50,
            caseType: "OLL",
            name: "W-case 2",
            primaryAlgorithm: "R' U' R U' R' U R U F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 L' U' L U' L' U L U B L U L' U' B'",
                "r' U' R U' R' U2 r y R U' R'"
            ],
            diagramImagePlaceholder: "oll_50"
        ),
        CubeCase(
            caseNumber: 51,
            caseType: "OLL",
            name: "Bottle/Line 5",
            primaryAlgorithm: "f R U R' U' f' U' F R U R' U' F'",
            alternativeAlgorithms: [
                "y2 f R U R' U' f' U' F R U R' U' F'",
                "F R U R' U' F' U F R U R' U' F'"
            ],
            diagramImagePlaceholder: "oll_51"
        ),
        CubeCase(
            caseNumber: 52,
            caseType: "OLL",
            name: "Bottle/Line 6",
            primaryAlgorithm: "R U R' U R U' B U' B' R'",
            alternativeAlgorithms: [
                "y2 F R U R' U' F' U' F R U R' U' F'",
                "R U2 R2' F R F' U2 R' F R F'"
            ],
            diagramImagePlaceholder: "oll_52"
        ),
        CubeCase(
            caseNumber: 53,
            caseType: "OLL",
            name: "Awning 2",
            primaryAlgorithm: "r' U' R U' R' U R U' R' U2 r",
            alternativeAlgorithms: [
                "y2 l' U' L U' L' U L U' L' U2 l",
                "F R U R' U' F' y' R U R' U' R' F R F'"
            ],
            diagramImagePlaceholder: "oll_53"
        ),
        CubeCase(
            caseNumber: 54,
            caseType: "OLL",
            name: "Awning 2 Variant",
            primaryAlgorithm: "r U R' U R U' R' U R U2' r'",
            alternativeAlgorithms: [
                "y2 l U L' U L U' L' U L U2' l'",
                "f R U R' U' f' y R U R' U' R' F R F'"
            ],
            diagramImagePlaceholder: "oll_54"
        ),
        CubeCase(
            caseNumber: 55,
            caseType: "OLL",
            name: "Squeeze/T-case 5",
            primaryAlgorithm: "R' F R U R' U' F' U R",
            alternativeAlgorithms: [
                "y2 L' B L U L' U' B' U L",
                "R U2 R2 U' R U' R' U2 F R F'"
            ],
            diagramImagePlaceholder: "oll_55"
        ),
        CubeCase(
            caseNumber: 56,
            caseType: "OLL",
            name: "Squeeze/T-case 6",
            primaryAlgorithm: "r U r' U R U' R' U R U' R' r U' r'",
            alternativeAlgorithms: [
                "y' F R U R' U' F' f R U R' U' f'",
                "y2 L' U' L U L F' L' F U' L' U L"
            ],
            diagramImagePlaceholder: "oll_56"
        ),
        CubeCase(
            caseNumber: 57,
            caseType: "OLL",
            name: "Stealth",
            primaryAlgorithm: "R U R' U' M' U R U' r'",
            alternativeAlgorithms: [
                "y L U L' U' M' U L U' l'",
                "y2 r U R' U' r' R U R U' R'"
            ],
            diagramImagePlaceholder: "oll_57"
        )
    ]

    public static let pllCases: [CubeCase] = [
        // --- Group 2: All 21 PLL Cases ---
        CubeCase(
            caseNumber: 1,
            caseType: "PLL",
            name: "Aa-Perm",
            primaryAlgorithm: "x L D' L U2 L' D L U2 L2' x'",
            alternativeAlgorithms: [
                "y' x' R' D R' U2 R D' R' U2 R2 x",
                "y2 x R' U R' D2 R U' R' D2 R2 x'"
            ],
            diagramImagePlaceholder: "pll_aa",
            auf: "U / U'",
            recognitionTip: "Headlights on left + bar on right"
        ),
        CubeCase(
            caseNumber: 2,
            caseType: "PLL",
            name: "Ab-Perm",
            primaryAlgorithm: "x L2' U2 L D L' U2 L D' L x'",
            alternativeAlgorithms: [
                "y' x' R2 D2 R U R' D2 R U' R x",
                "y2 x R D' R U2 R' D R U2 R2 x'"
            ],
            diagramImagePlaceholder: "pll_ab",
            auf: "U / U'",
            recognitionTip: "Headlights on right + bar on left"
        ),
        CubeCase(
            caseNumber: 3,
            caseType: "PLL",
            name: "F-Perm",
            primaryAlgorithm: "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R",
            alternativeAlgorithms: [
                "y' R' U2 R' d' R' F' R2 U' R' U R' F R U' F",
                "y2 x' R U' R' D R U R' D' R U R' D R U' R' D' x"
            ],
            diagramImagePlaceholder: "pll_f",
            auf: "U",
            recognitionTip: "Two bars opposite + headlights"
        ),
        CubeCase(
            caseNumber: 4,
            caseType: "PLL",
            name: "Ga-Perm",
            primaryAlgorithm: "R2 U R' U R' U' R U' R2 D U' R' U R D'",
            alternativeAlgorithms: [
                "y2 R2 u R' U R' U' R u' R2' y' R' U R",
                "R2' F2 R U2 R U2' R' F R U R' U' R' F R2"
            ],
            diagramImagePlaceholder: "pll_ga"
        ),
        CubeCase(
            caseNumber: 5,
            caseType: "PLL",
            name: "Gb-Perm",
            primaryAlgorithm: "F' U' F R2 u R' U R U' R u' R2'",
            alternativeAlgorithms: [
                "y' D R' U' R D' R2 u B' U B u' R2",
                "y2 R' U' R y R2' u R' U R U' R u' R2'"
            ],
            diagramImagePlaceholder: "pll_gb"
        ),
        CubeCase(
            caseNumber: 6,
            caseType: "PLL",
            name: "Gc-Perm",
            primaryAlgorithm: "R2' U' R U' R U R' U R2 D' U R U' R' D",
            alternativeAlgorithms: [
                "y2 R2' u' R U' R U R' u R2 y R U' R'",
                "y' R2 F2 R' U2 R' U2 R F' R' U' R U R F R2"
            ],
            diagramImagePlaceholder: "pll_gc"
        ),
        CubeCase(
            caseNumber: 7,
            caseType: "PLL",
            name: "Gd-Perm",
            primaryAlgorithm: "R U R' y' R2' u' R U' R' U R' u R2",
            alternativeAlgorithms: [
                "y2 f R' f' R2 u' R U' R' U R' u R2",
                "y' R U R' F' U' F R2 u' R U' R' U R' u R2"
            ],
            diagramImagePlaceholder: "pll_gd"
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
            diagramImagePlaceholder: "pll_e"
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
            diagramImagePlaceholder: "pll_h"
        ),
        CubeCase(
            caseNumber: 10,
            caseType: "PLL",
            name: "Ja-Perm",
            primaryAlgorithm: "x R2 F R F' R U2' r' U r U2' x'",
            alternativeAlgorithms: [
                "y2 L' U2 L U L' U2' R U' L U R'",
                "y' L' U R U' L U2 R' U R U2 R'"
            ],
            diagramImagePlaceholder: "pll_ja"
        ),
        CubeCase(
            caseNumber: 11,
            caseType: "PLL",
            name: "Jb-Perm",
            primaryAlgorithm: "R U R' F' R U R' U' R' F R2 U' R'",
            alternativeAlgorithms: [
                "y2 L U2 L' U' L U2 R' U L' U' R",
                "R U2 R' U' R U2' L' U R' U' L"
            ],
            diagramImagePlaceholder: "pll_jb"
        ),
        CubeCase(
            caseNumber: 12,
            caseType: "PLL",
            name: "Na-Perm",
            primaryAlgorithm: "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'",
            alternativeAlgorithms: [
                "z U R' D R2 U' R D' U R' D R2 U' R D' z'",
                "y2 R U R' U R U R' F' R U R' U' R' F R2 U' R2' F R F'"
            ],
            diagramImagePlaceholder: "pll_na"
        ),
        CubeCase(
            caseNumber: 13,
            caseType: "PLL",
            name: "Nb-Perm",
            primaryAlgorithm: "R' U R U' R' F' U' F R U R' F R' F' R U' R",
            alternativeAlgorithms: [
                "z U' R D' R2' U R' D U' R D' R2' U R' D z'",
                "y2 R' U L' U2 R U' L R' U L' U2 R U' L"
            ],
            diagramImagePlaceholder: "pll_nb"
        ),
        CubeCase(
            caseNumber: 14,
            caseType: "PLL",
            name: "Ra-Perm",
            primaryAlgorithm: "R U' R' U' R U R D R' U' R D' R' U2 R'",
            alternativeAlgorithms: [
                "y2 R U R' F' R U2 R' U2' R' F R U R U2' R'",
                "y' L U2 L' U2 L F' L' U' L U L F L2'"
            ],
            diagramImagePlaceholder: "pll_ra"
        ),
        CubeCase(
            caseNumber: 15,
            caseType: "PLL",
            name: "Rb-Perm",
            primaryAlgorithm: "R' U2 R U2 R' F R U R' U' R' F' R2 U' R'",
            alternativeAlgorithms: [
                "y2 R' U R U R' F' R U R' U' R' F R2 U2' R'",
                "y L' U L' d' L' U' L D L' U L D' L U2 L"
            ],
            diagramImagePlaceholder: "pll_rb"
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
            diagramImagePlaceholder: "pll_t"
        ),
        CubeCase(
            caseNumber: 17,
            caseType: "PLL",
            name: "Ua-Perm",
            primaryAlgorithm: "M2' U M' U2 M U M2'",
            alternativeAlgorithms: [
                "y2 R U' R U R U R U' R' U' R2",
                "y' R' U R' U' R' U' R' U R U R2"
            ],
            diagramImagePlaceholder: "pll_ua"
        ),
        CubeCase(
            caseNumber: 18,
            caseType: "PLL",
            name: "Ub-Perm",
            primaryAlgorithm: "M2' U' M' U2 M U' M2'",
            alternativeAlgorithms: [
                "y2 R2 U R U R' U' R' U' R' U R'",
                "y' R U R' U R' U' R2 U' R' U R' U R"
            ],
            diagramImagePlaceholder: "pll_ub"
        ),
        CubeCase(
            caseNumber: 19,
            caseType: "PLL",
            name: "V-Perm",
            primaryAlgorithm: "R' U R' d' R' F' R2 U' R' U R' F R U' F",
            alternativeAlgorithms: [
                "y R' U R' U' y R' F' R2 U' R' U R' F R F",
                "y2 x' R' U R' D2 R U' R' D2 R2 x"
            ],
            diagramImagePlaceholder: "pll_v"
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
            diagramImagePlaceholder: "pll_y"
        ),
        CubeCase(
            caseNumber: 21,
            caseType: "PLL",
            name: "Z-Perm",
            primaryAlgorithm: "M' U M2' U M2' U M' U2 M2'",
            alternativeAlgorithms: [
                "y M2' U M2' U M' U2 M2' U2 M'",
                "y' R' U' R U' R U R U' R' U R U R2 U' R'"
            ],
            diagramImagePlaceholder: "pll_z"
        )
    ]
}
