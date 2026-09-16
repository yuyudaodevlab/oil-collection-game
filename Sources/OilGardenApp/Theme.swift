import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
    static let garden = Color(hex: 0x142E28)
    static let paper = Color(hex: 0xF6EFDA)
    static let quiet = Color(hex: 0xB9C6AD)
    static let gold = Color(hex: 0xEFC77A)
}

enum Broth: String, CaseIterable, Identifiable {
    case shoyu, shio, miso
    var id: String { rawValue }
    var name: String {
        switch self { case .shoyu: return "醤油"; case .shio: return "塩"; case .miso: return "味噌" }
    }
    var subtitle: String {
        switch self { case .shoyu: return "琥珀に、ひと息。"; case .shio: return "透きとおる、ひと休み。"; case .miso: return "ほっと、ほどける。" }
    }
    var light: Color {
        switch self { case .shoyu: return Color(hex: 0xC68535); case .shio: return Color(hex: 0xD6BB72); case .miso: return Color(hex: 0xC69251) }
    }
    var dark: Color {
        switch self { case .shoyu: return Color(hex: 0x643419); case .shio: return Color(hex: 0x8D763F); case .miso: return Color(hex: 0x80502A) }
    }
    var oil: Color {
        switch self { case .shoyu: return Color(hex: 0xFFD570); case .shio: return Color(hex: 0xFFF0A1); case .miso: return Color(hex: 0xFFD58A) }
    }
}

struct Keepsake: Identifiable {
    let id: Int
    let name: String
    let note: String
    let needed: Int
    let symbol: String
    static let all: [Keepsake] = [
        .init(id: 0, name: "ひとしずく", note: "はじめて、ぷるん。", needed: 1, symbol: "drop.fill"),
        .init(id: 1, name: "ふたつの輪", note: "出会って、ひとつに。", needed: 12, symbol: "circle.dotted.circle.fill"),
        .init(id: 2, name: "小さな月", note: "スープに浮かぶ月あかり。", needed: 40, symbol: "moon.fill"),
        .init(id: 3, name: "花ひらく", note: "何もしない、いい時間。", needed: 100, symbol: "camera.macro"),
        .init(id: 4, name: "まあるい宇宙", note: "今日も、気の向くまま。", needed: 250, symbol: "sparkles")
    ]
}
