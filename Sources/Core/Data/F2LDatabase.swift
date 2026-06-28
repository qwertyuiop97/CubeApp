import Foundation

// F2L cases as a separate database (per planning decision and AGENTS.md protection of AlgorithmDatabase.swift)
// All cases use caseType "F2L". Each has primary + ≥2 alternatives.

public struct F2LDatabase {
    public static let f2lCases: [CubeCase] = [
        // 1
        CubeCase(caseNumber: 1, caseType: "F2L", name: "Basic FR",
            primaryAlgorithm: "R U' R'",
            alternativeAlgorithms: ["y' R' F R F'", "F' U' F"],
            diagramImagePlaceholder: "f2l_1"),
        // 2
        CubeCase(caseNumber: 2, caseType: "F2L", name: "Basic FL",
            primaryAlgorithm: "L' U L",
            alternativeAlgorithms: ["y R F' R' F", "F U F'"],
            diagramImagePlaceholder: "f2l_2"),
        // 3
        CubeCase(caseNumber: 3, caseType: "F2L", name: "Pair Ready FR",
            primaryAlgorithm: "R U R'",
            alternativeAlgorithms: ["y' R' F R F'", "U R U' R'"],
            diagramImagePlaceholder: "f2l_3"),
        // 4
        CubeCase(caseNumber: 4, caseType: "F2L", name: "Pair Ready FL",
            primaryAlgorithm: "L' U' L",
            alternativeAlgorithms: ["y R F' R' F", "U' L' U L"],
            diagramImagePlaceholder: "f2l_4"),
        // 5
        CubeCase(caseNumber: 5, caseType: "F2L", name: "Edge Flip FR",
            primaryAlgorithm: "R U2 R' U' R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U' R U' R'", "F' U2 F U F' U F"],
            diagramImagePlaceholder: "f2l_5"),
        // 6
        CubeCase(caseNumber: 6, caseType: "F2L", name: "Edge Flip FL",
            primaryAlgorithm: "L' U2 L U L' U L",
            alternativeAlgorithms: ["y R F' R' F U L' U L", "F U2 F' U' F U' F'"],
            diagramImagePlaceholder: "f2l_6"),
        // 7
        CubeCase(caseNumber: 7, caseType: "F2L", name: "Corner Flip FR",
            primaryAlgorithm: "R U R' U R U2 R'",
            alternativeAlgorithms: ["y' R' F R F' U R U R'", "U R U' R' U R U R'"],
            diagramImagePlaceholder: "f2l_7"),
        // 8
        CubeCase(caseNumber: 8, caseType: "F2L", name: "Corner Flip FL",
            primaryAlgorithm: "L' U' L U' L' U2 L",
            alternativeAlgorithms: ["y R F' R' F U' L' U' L", "U' L' U L U' L' U' L"],
            diagramImagePlaceholder: "f2l_8"),
        // 9
        CubeCase(caseNumber: 9, caseType: "F2L", name: "Both Flip FR",
            primaryAlgorithm: "R U' R' U' R U R' U2 R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U' R U R' U' R U' R'", "F' U F U' F' U' F"],
            diagramImagePlaceholder: "f2l_9"),
        // 10
        CubeCase(caseNumber: 10, caseType: "F2L", name: "Both Flip FL",
            primaryAlgorithm: "L' U L U L' U' L U2 L' U L",
            alternativeAlgorithms: ["y R F' R' F U L' U' L U L' U L", "F U' F' U F U F'"],
            diagramImagePlaceholder: "f2l_10"),
        // 11
        CubeCase(caseNumber: 11, caseType: "F2L", name: "Back Slot FR",
            primaryAlgorithm: "R' U' R U' R' U2 R",
            alternativeAlgorithms: ["y' R F' R' F U' R' U' R", "U2 R' U' R U' R' U2 R"],
            diagramImagePlaceholder: "f2l_11"),
        // 12
        CubeCase(caseNumber: 12, caseType: "F2L", name: "Back Slot FL",
            primaryAlgorithm: "L U L' U L U2 L'",
            alternativeAlgorithms: ["y R' F R F' U L U L'", "U2 L U L' U L U2 L'"],
            diagramImagePlaceholder: "f2l_12"),
        // 13
        CubeCase(caseNumber: 13, caseType: "F2L", name: "Split Pair FR",
            primaryAlgorithm: "R U' R' U R U R'",
            alternativeAlgorithms: ["y' R' F R F' U' R U R'", "U R U' R' U' R U R'"],
            diagramImagePlaceholder: "f2l_13"),
        // 14
        CubeCase(caseNumber: 14, caseType: "F2L", name: "Split Pair FL",
            primaryAlgorithm: "L' U L U' L' U' L",
            alternativeAlgorithms: ["y R F' R' F U L' U' L", "U' L' U L U L' U' L"],
            diagramImagePlaceholder: "f2l_14"),
        // 15
        CubeCase(caseNumber: 15, caseType: "F2L", name: "Connected Pair FR",
            primaryAlgorithm: "R U R' U' R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U R U' R'", "U' R U R' U R U' R'"],
            diagramImagePlaceholder: "f2l_15"),
        // 16
        CubeCase(caseNumber: 16, caseType: "F2L", name: "Connected Pair FL",
            primaryAlgorithm: "L' U' L U L' U L",
            alternativeAlgorithms: ["y R F' R' F U' L' U L", "U L' U' L U' L' U L"],
            diagramImagePlaceholder: "f2l_16"),
        // 17
        CubeCase(caseNumber: 17, caseType: "F2L", name: "White on Top FR",
            primaryAlgorithm: "R U' R' U2 R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U2 R U' R'", "U2 R U' R' U' R U' R'"],
            diagramImagePlaceholder: "f2l_17"),
        // 18
        CubeCase(caseNumber: 18, caseType: "F2L", name: "White on Top FL",
            primaryAlgorithm: "L' U L U2 L' U L",
            alternativeAlgorithms: ["y R F' R' F U2 L' U L", "U2 L' U L U L' U L"],
            diagramImagePlaceholder: "f2l_18"),
        // 19
        CubeCase(caseNumber: 19, caseType: "F2L", name: "Sledge FR",
            primaryAlgorithm: "R' F R F'",
            alternativeAlgorithms: ["y' R U' R'", "F' U' F"],
            diagramImagePlaceholder: "f2l_19"),
        // 20
        CubeCase(caseNumber: 20, caseType: "F2L", name: "Sledge FL",
            primaryAlgorithm: "L F' L' F",
            alternativeAlgorithms: ["y R' U R", "F U F'"],
            diagramImagePlaceholder: "f2l_20"),
        // 21
        CubeCase(caseNumber: 21, caseType: "F2L", name: "Hedgeslammer FR",
            primaryAlgorithm: "F R' F' R",
            alternativeAlgorithms: ["y' R U R'", "F' U' F"],
            diagramImagePlaceholder: "f2l_21"),
        // 22
        CubeCase(caseNumber: 22, caseType: "F2L", name: "Hedgeslammer FL",
            primaryAlgorithm: "F' L F L'",
            alternativeAlgorithms: ["y R' U' R", "F U F'"],
            diagramImagePlaceholder: "f2l_22"),
        // 23
        CubeCase(caseNumber: 23, caseType: "F2L", name: "Wide Sledge FR",
            primaryAlgorithm: "r U' r' F R' F' R",
            alternativeAlgorithms: ["R' F R F' U' R U' R'", "y' r U' r' U' R U' R'"],
            diagramImagePlaceholder: "f2l_23"),
        // 24
        CubeCase(caseNumber: 24, caseType: "F2L", name: "Wide Sledge FL",
            primaryAlgorithm: "l' U l F' L F L'",
            alternativeAlgorithms: ["L F' L' F U L' U L", "y l' U l U L' U L"],
            diagramImagePlaceholder: "f2l_24"),
        // 25
        CubeCase(caseNumber: 25, caseType: "F2L", name: "Keyhole FR",
            primaryAlgorithm: "R U' R' U' R U R' U' R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U' R U R' U' R U' R'", "U R U' R' U' R U R' U' R U' R'"],
            diagramImagePlaceholder: "f2l_25"),
        // 26
        CubeCase(caseNumber: 26, caseType: "F2L", name: "Keyhole FL",
            primaryAlgorithm: "L' U L U L' U' L U L' U L",
            alternativeAlgorithms: ["y R F' R' F U L' U' L U L' U L", "U' L' U L U L' U' L U L' U L"],
            diagramImagePlaceholder: "f2l_26"),
        // 27
        CubeCase(caseNumber: 27, caseType: "F2L", name: "Free Pair FR",
            primaryAlgorithm: "R U R' U' R U R'",
            alternativeAlgorithms: ["y' R' F R F' U R U R'", "U R U' R' U R U R'"],
            diagramImagePlaceholder: "f2l_27"),
        // 28
        CubeCase(caseNumber: 28, caseType: "F2L", name: "Free Pair FL",
            primaryAlgorithm: "L' U' L U L' U' L",
            alternativeAlgorithms: ["y R F' R' F U' L' U' L", "U' L' U L U' L' U' L"],
            diagramImagePlaceholder: "f2l_28"),
        // 29
        CubeCase(caseNumber: 29, caseType: "F2L", name: "F2L 29",
            primaryAlgorithm: "R U2 R' U R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U2 R U' R'", "U R U' R' U2 R U' R'"],
            diagramImagePlaceholder: "f2l_29"),
        // 30
        CubeCase(caseNumber: 30, caseType: "F2L", name: "F2L 30",
            primaryAlgorithm: "L' U2 L U' L' U L",
            alternativeAlgorithms: ["y R F' R' F U2 L' U L", "U' L' U L U2 L' U L"],
            diagramImagePlaceholder: "f2l_30"),
        // 31
        CubeCase(caseNumber: 31, caseType: "F2L", name: "F2L 31",
            primaryAlgorithm: "R U R' U R U2 R'",
            alternativeAlgorithms: ["y' R' F R F' U R U R'", "U R U' R' U R U2 R'"],
            diagramImagePlaceholder: "f2l_31"),
        // 32
        CubeCase(caseNumber: 32, caseType: "F2L", name: "F2L 32",
            primaryAlgorithm: "L' U' L U' L' U2 L",
            alternativeAlgorithms: ["y R F' R' F U' L' U' L", "U' L' U L U' L' U2 L"],
            diagramImagePlaceholder: "f2l_32"),
        // 33
        CubeCase(caseNumber: 33, caseType: "F2L", name: "F2L 33",
            primaryAlgorithm: "R U' R' U' R U2 R'",
            alternativeAlgorithms: ["y' R' F R F' U' R U' R'", "U' R U R' U' R U2 R'"],
            diagramImagePlaceholder: "f2l_33"),
        // 34
        CubeCase(caseNumber: 34, caseType: "F2L", name: "F2L 34",
            primaryAlgorithm: "L' U L U L' U2 L",
            alternativeAlgorithms: ["y R F' R' F U L' U L", "U L' U' L U L' U2 L"],
            diagramImagePlaceholder: "f2l_34"),
        // 35
        CubeCase(caseNumber: 35, caseType: "F2L", name: "F2L 35",
            primaryAlgorithm: "R U R' U2 R U' R' U R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U2 R U' R' U R U' R'", "U R U' R' U2 R U' R' U R U' R'"],
            diagramImagePlaceholder: "f2l_35"),
        // 36
        CubeCase(caseNumber: 36, caseType: "F2L", name: "F2L 36",
            primaryAlgorithm: "L' U' L U2 L' U L U' L' U L",
            alternativeAlgorithms: ["y R F' R' F U2 L' U L U' L' U L", "U' L' U L U2 L' U L U' L' U L"],
            diagramImagePlaceholder: "f2l_36"),
        // 37
        CubeCase(caseNumber: 37, caseType: "F2L", name: "F2L 37",
            primaryAlgorithm: "R U' R' U R U R' U R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U' R U R' U R U' R'", "U R U' R' U R U R' U R U' R'"],
            diagramImagePlaceholder: "f2l_37"),
        // 38
        CubeCase(caseNumber: 38, caseType: "F2L", name: "F2L 38",
            primaryAlgorithm: "L' U L U' L' U' L U' L' U L",
            alternativeAlgorithms: ["y R F' R' F U L' U' L U' L' U L", "U' L' U L U' L' U' L U' L' U L"],
            diagramImagePlaceholder: "f2l_38"),
        // 39
        CubeCase(caseNumber: 39, caseType: "F2L", name: "F2L 39",
            primaryAlgorithm: "R U2 R2 U' R2 U' R2 U2 R",
            alternativeAlgorithms: ["y' R' F R2 F' R2 F R' F' R", "U2 R2 U R2 U R2 U2 R2"],
            diagramImagePlaceholder: "f2l_39"),
        // 40
        CubeCase(caseNumber: 40, caseType: "F2L", name: "F2L 40",
            primaryAlgorithm: "R U R' U' R U' R' U2 R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U R U' R' U2 R U' R'", "U R U' R' U' R U' R' U2 R U' R'"],
            diagramImagePlaceholder: "f2l_40"),
        // 41
        CubeCase(caseNumber: 41, caseType: "F2L", name: "F2L 41",
            primaryAlgorithm: "R U' R' U R U R' U' R U' R'",
            alternativeAlgorithms: ["y' R' F R F' U' R U R' U' R U' R'", "U' R U R' U R U' R' U' R U' R'"],
            diagramImagePlaceholder: "f2l_41")
    ]
}
