import SwiftUI

struct StickerPattern {
    var uFace: [Bool]
    var frontTop: [Color]
    var rightTop: [Color]
    var backTop: [Color]
    var leftTop: [Color]
}

enum StickerDatabase {
    static func pattern(for caseID: String) -> StickerPattern? {
        let gray: Color = Color(white: 0.3)
        switch caseID {
        // OLL
        case "OLL-1": return StickerPattern(uFace: [false,false,false,false,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-2": return StickerPattern(uFace: [false,false,false,false,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-3": return StickerPattern(uFace: [false,true,false,false,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-4": return StickerPattern(uFace: [false,false,false,false,true,false,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-5": return StickerPattern(uFace: [true,false,false,false,true,false,false,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-6": return StickerPattern(uFace: [false,false,true,false,true,false,true,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-7": return StickerPattern(uFace: [false,false,true,false,true,false,false,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-8": return StickerPattern(uFace: [true,false,false,false,true,false,true,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-9": return StickerPattern(uFace: [false,false,true,false,true,false,true,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-10": return StickerPattern(uFace: [true,false,false,false,true,false,false,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-11": return StickerPattern(uFace: [false,false,true,true,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-12": return StickerPattern(uFace: [false,true,false,false,true,true,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-13": return StickerPattern(uFace: [false,false,false,true,true,false,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-14": return StickerPattern(uFace: [false,false,false,false,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-15": return StickerPattern(uFace: [false,false,false,false,true,false,false,true,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-16": return StickerPattern(uFace: [false,false,false,false,true,false,true,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-17": return StickerPattern(uFace: [false,false,false,true,true,true,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-18": return StickerPattern(uFace: [false,true,false,false,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-19": return StickerPattern(uFace: [false,false,false,false,true,false,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-20": return StickerPattern(uFace: [false,true,false,false,true,false,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        // OLL 21-27: all 4 edges oriented (cross done), corners vary
        case "OLL-21": return StickerPattern(uFace: [false,true,false,true,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-22": return StickerPattern(uFace: [false,true,false,true,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-23": return StickerPattern(uFace: [false,true,false,true,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        // OLL 24-27: cross + specific corners yellow
        case "OLL-24": return StickerPattern(uFace: [false,true,true,true,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-25": return StickerPattern(uFace: [false,true,false,true,true,true,false,true,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-26": return StickerPattern(uFace: [true,true,false,true,true,true,true,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-27": return StickerPattern(uFace: [false,true,true,true,true,true,false,true,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-28": return StickerPattern(uFace: [false,true,false,false,true,false,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-29": return StickerPattern(uFace: [false,false,true,false,true,false,true,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-30": return StickerPattern(uFace: [true,false,false,false,true,false,false,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-31": return StickerPattern(uFace: [false,true,false,false,true,false,true,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-32": return StickerPattern(uFace: [false,true,false,false,true,false,false,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-33": return StickerPattern(uFace: [false,true,false,true,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-34": return StickerPattern(uFace: [false,false,false,true,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-35": return StickerPattern(uFace: [true,false,true,false,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-36": return StickerPattern(uFace: [false,false,false,false,true,false,true,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-37": return StickerPattern(uFace: [false,true,false,false,true,false,true,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-38": return StickerPattern(uFace: [true,false,true,false,true,false,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-39": return StickerPattern(uFace: [true,false,false,true,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-40": return StickerPattern(uFace: [false,false,false,false,true,true,false,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-41": return StickerPattern(uFace: [false,false,true,false,true,true,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-42": return StickerPattern(uFace: [false,true,false,true,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-43": return StickerPattern(uFace: [false,true,false,false,true,false,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-44": return StickerPattern(uFace: [false,true,false,true,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-45": return StickerPattern(uFace: [false,true,false,true,true,true,false,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-46": return StickerPattern(uFace: [true,true,false,true,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-47": return StickerPattern(uFace: [false,false,false,false,true,false,false,true,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-48": return StickerPattern(uFace: [false,false,false,true,true,false,true,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-49": return StickerPattern(uFace: [true,false,false,true,true,false,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-50": return StickerPattern(uFace: [false,false,false,false,true,true,false,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-51": return StickerPattern(uFace: [true,true,false,false,true,false,false,true,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-52": return StickerPattern(uFace: [false,true,true,false,true,false,true,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-53": return StickerPattern(uFace: [true,true,false,true,true,false,true,true,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-54": return StickerPattern(uFace: [false,true,true,false,true,true,false,true,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-55": return StickerPattern(uFace: [true,false,true,true,true,true,false,false,false], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-56": return StickerPattern(uFace: [false,false,false,true,true,true,true,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])
        case "OLL-57": return StickerPattern(uFace: [true,false,true,true,true,true,true,false,true], frontTop: [gray,gray,gray], rightTop: [gray,gray,gray], backTop: [gray,gray,gray], leftTop: [gray,gray,gray])

        // PLL
        case "PLL-1": // Aa
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.red], rightTop: [.orange,.green,.green], backTop: [.orange,.orange,.green], leftTop: [.blue,.blue,.orange])
        case "PLL-2": // Ab
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.red], rightTop: [.green,.green,.orange], backTop: [.blue,.orange,.orange], leftTop: [.blue,.blue,.green])
        case "PLL-3": // F-Perm
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.green,.orange], rightTop: [.blue,.green,.red], backTop: [.red,.orange,.orange], leftTop: [.blue,.blue,.green])
        case "PLL-4": // Ga-Perm
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.orange,.red,.red], rightTop: [.red,.green,.green], backTop: [.green,.orange,.orange], leftTop: [.blue,.blue,.blue])
        case "PLL-5": // Gb-Perm
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.green,.red,.red], rightTop: [.orange,.green,.green], backTop: [.red,.orange,.orange], leftTop: [.blue,.blue,.blue])
        case "PLL-6": // Gc-Perm
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.orange], rightTop: [.green,.green,.red], backTop: [.orange,.orange,.green], leftTop: [.blue,.blue,.blue])
        case "PLL-7": // Gd-Perm
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.green], rightTop: [.green,.green,.orange], backTop: [.orange,.orange,.red], leftTop: [.blue,.blue,.blue])
        case "PLL-8": // E-Perm
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.orange,.red], rightTop: [.green,.red,.green], backTop: [.orange,.green,.orange], leftTop: [.blue,.orange,.blue])
        case "PLL-9": // H
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.orange,.red], rightTop: [.green,.blue,.green], backTop: [.orange,.red,.orange], leftTop: [.blue,.green,.blue])
        case "PLL-10": // Ja
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.red], rightTop: [.green,.blue,.green], backTop: [.orange,.orange,.orange], leftTop: [.green,.blue,.blue])
        case "PLL-11": // Jb
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.red], rightTop: [.blue,.green,.green], backTop: [.orange,.orange,.orange], leftTop: [.blue,.blue,.green])
        case "PLL-12": // Na
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.orange,.red], rightTop: [.green,.blue,.green], backTop: [.orange,.red,.orange], leftTop: [.blue,.green,.blue])
        case "PLL-13": // Nb
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.orange,.red], rightTop: [.green,.blue,.green], backTop: [.orange,.red,.orange], leftTop: [.blue,.green,.blue])
        case "PLL-14": // Ra
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.red], rightTop: [.orange,.green,.green], backTop: [.green,.orange,.orange], leftTop: [.blue,.blue,.blue])
        case "PLL-15": // Rb
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.red], rightTop: [.green,.green,.blue], backTop: [.orange,.orange,.orange], leftTop: [.green,.blue,.blue])
        case "PLL-16": // T
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.green,.red], rightTop: [.blue,.green,.green], backTop: [.orange,.orange,.orange], leftTop: [.blue,.blue,.red])
        case "PLL-17": // Ua
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.orange,.red,.red], rightTop: [.green,.green,.green], backTop: [.red,.orange,.orange], leftTop: [.blue,.blue,.blue])
        case "PLL-18": // Ub
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.green,.red,.red], rightTop: [.green,.green,.green], backTop: [.orange,.orange,.orange], leftTop: [.blue,.blue,.orange])
        case "PLL-19": // V
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.red,.orange], rightTop: [.green,.blue,.green], backTop: [.red,.orange,.orange], leftTop: [.blue,.green,.blue])
        case "PLL-20": // Y
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.red,.orange,.red], rightTop: [.green,.green,.blue], backTop: [.orange,.red,.orange], leftTop: [.green,.blue,.blue])
        case "PLL-21": // Z
            return StickerPattern(uFace: Array(repeating: true, count: 9),
                frontTop: [.green,.red,.green], rightTop: [.red,.green,.red], backTop: [.blue,.orange,.blue], leftTop: [.orange,.blue,.orange])
        default:
            return nil
        }
    }
}
