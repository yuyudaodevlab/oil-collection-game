import SwiftUI

/// Resolution-independent artwork. Static ingredients are rendered separately from the simulation.
struct RamenArt: View, Equatable {
    let broth: Broth
    var layer: ArtLayer = .complete
    enum ArtLayer { case complete, soup, toppings }
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 1000
            context.scaleBy(x: scale, y: scale)
            if layer != .toppings {
                drawBowl(&context)
                drawSoup(&context)
                drawNoodles(&context)
            }
            if layer != .soup {
            drawNori(&context, at: CGPoint(x: 722, y: 259), angle: 0.42)
            drawPork(&context, at: CGPoint(x: 281, y: 294), angle: -0.45)
            drawPork(&context, at: CGPoint(x: 239, y: 370), angle: -0.7)
            drawEgg(&context, at: CGPoint(x: 748, y: 675), angle: -0.6)
            drawScallions(&context)
            }
        }
        .accessibilityHidden(true)
    }

    private func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Path {
        Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
    }
    private func drawBowl(_ c: inout GraphicsContext) {
        c.drawLayer { shadow in
            shadow.addFilter(.blur(radius: 24))
            shadow.fill(ellipse(56, 100, 900, 884), with: .color(.black.opacity(0.32)))
        }
        c.fill(ellipse(37, 34, 926, 926), with: .linearGradient(
            Gradient(colors: [Color(hex: 0xFFFFEF), Color(hex: 0xD8D8C8), Color(hex: 0x9EADA1)]),
            startPoint: .init(x: 180, y: 50), endPoint: .init(x: 840, y: 930)))
        c.stroke(ellipse(45, 42, 910, 910), with: .color(.white.opacity(0.68)), lineWidth: 3)
        c.stroke(ellipse(66, 63, 868, 868), with: .color(Color(hex: 0x385D56).opacity(0.8)), lineWidth: 5)
        c.stroke(ellipse(77, 74, 846, 846), with: .color(Color(hex: 0x527569).opacity(0.5)), lineWidth: 2)
        // A quiet hand-painted ceramic pattern around the rim.
        for i in 0..<68 {
            let a = Double(i) / 68 * .pi * 2
            var p = Path()
            p.move(to: .init(x: 500 + cos(a) * 427, y: 497 + sin(a) * 427))
            p.addLine(to: .init(x: 500 + cos(a + 0.012) * 438, y: 497 + sin(a + 0.012) * 438))
            c.stroke(p, with: .color(Color(hex: 0x386359).opacity(i % 3 == 0 ? 0.6 : 0.23)), lineWidth: 3)
        }
        c.fill(ellipse(98, 96, 804, 804), with: .color(Color(hex: 0x524838)))
        c.stroke(ellipse(101, 99, 798, 798), with: .color(.black.opacity(0.15)), lineWidth: 8)
    }
    private func drawSoup(_ c: inout GraphicsContext) {
        c.fill(ellipse(110, 110, 780, 780), with: .radialGradient(
            Gradient(colors: [broth.light, broth.light, broth.dark]),
            center: .init(x: 433, y: 395), startRadius: 12, endRadius: 510))
        var clipped = c
        clipped.clip(to: ellipse(113, 113, 774, 774))
        for i in 0..<620 {
            let x = noise(i * 5 + 1) * 1000, y = noise(i * 5 + 2) * 1000
            let r = 0.7 + noise(i * 5 + 3) * 2.4
            clipped.fill(ellipse(x, y, r, r), with: .color((i % 3 == 0 ? Color.paper : broth.dark).opacity(0.16)))
        }
        var shine = Path()
        shine.addArc(center: .init(x: 500, y: 500), radius: 378, startAngle: .degrees(194), endAngle: .degrees(284), clockwise: false)
        c.stroke(shine, with: .color(Color(hex: 0xFFECC2).opacity(0.42)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        for i in 0..<45 {
            let a = Double(i) * 2.399
            let r = 361.0 + noise(i + 9) * 15
            let s = 2 + noise(i + 44) * 5
            let p = ellipse(500 + cos(a) * r, 500 + sin(a) * r, s, s)
            c.fill(p, with: .color(broth.oil.opacity(0.3)))
            c.stroke(p, with: .color(broth.dark.opacity(0.5)), lineWidth: 0.7)
        }
    }
    private func drawNoodles(_ c: inout GraphicsContext) {
        var layer = c
        layer.clip(to: ellipse(122, 122, 756, 756))
        for i in 0..<18 {
            let offset = Double(i) * 7.5
            var noodle = Path()
            noodle.move(to: .init(x: 174 + offset * 0.25, y: 526 + offset * 0.48))
            // Loose individual curls beneath the broth, rather than parallel straight strands.
            noodle.addCurve(to: .init(x: 316 + offset * 0.65, y: 776 - offset * 0.10),
                            control1: .init(x: 91 + offset * 0.6, y: 703 + sin(Double(i)) * 32),
                            control2: .init(x: 316 + offset * 0.55, y: 640 + offset * 0.48))
            noodle.addCurve(to: .init(x: 645 + offset * 0.52, y: 811 - offset * 0.24),
                            control1: .init(x: 265 + offset * 0.5, y: 888 - offset * 0.34),
                            control2: .init(x: 597 + offset * 0.4, y: 681 + offset * 0.40))
            layer.stroke(noodle, with: .color(Color(hex: 0x69431F).opacity(0.30)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
            layer.stroke(noodle, with: .color(Color(hex: 0xE5BB68).opacity(0.56)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            layer.stroke(noodle, with: .color(Color(hex: 0xFFE2A0).opacity(0.32)), lineWidth: 1.6)
        }
    }

    private func drawNori(_ c: inout GraphicsContext, at center: CGPoint, angle: Double) {
        var l = c
        l.translateBy(x: center.x, y: center.y); l.rotate(by: .radians(angle))
        let rect = CGRect(x: -87, y: -104, width: 174, height: 208)
        l.addFilter(.shadow(color: .black.opacity(0.3), radius: 9, x: 3, y: 9))
        l.fill(Path(roundedRect: rect, cornerRadius: 8), with: .linearGradient(Gradient(colors: [Color(hex: 0x3A4430), Color(hex: 0x131E17)]), startPoint: .init(x: -80, y: -100), endPoint: .init(x: 60, y: 100)))
        for i in 0..<180 {
            let x = noise(i * 3 + 23) * 163 - 82, y = noise(i * 3 + 71) * 195 - 96
            var p = Path(); p.move(to: .init(x: x, y: y)); p.addLine(to: .init(x: x + 3, y: y + noise(i + 4) * 13))
            l.stroke(p, with: .color(Color(hex: 0xA3A16A).opacity(0.12)), lineWidth: 1.8)
        }
    }
    private func drawPork(_ c: inout GraphicsContext, at center: CGPoint, angle: Double) {
        var l = c
        l.translateBy(x: center.x, y: center.y); l.rotate(by: .radians(angle))
        l.drawLayer { s in
            s.addFilter(.shadow(color: .black.opacity(0.3), radius: 7, x: 2, y: 8))
            s.fill(ellipse(-109, -73, 218, 146), with: .color(Color(hex: 0x804A31)))
        }
        l.fill(ellipse(-104, -68, 208, 136), with: .linearGradient(Gradient(colors: [Color(hex: 0xF2C2A0), Color(hex: 0xBD7860)]), startPoint: .init(x: -30, y: -70), endPoint: .init(x: 40, y: 70)))
        for j in 0..<6 {
            let inset = Double(j) * 12
            l.stroke(ellipse(-94 + inset, -59 + inset * 0.59, 188 - inset * 2, 118 - inset * 1.18),
                     with: .color((j % 2 == 0 ? Color(hex: 0xFFE0B6) : Color(hex: 0xAB6350)).opacity(0.75)), lineWidth: j % 2 == 0 ? 7 : 5)
        }
        for i in 0..<60 {
            let a = noise(i + 9) * .pi * 2, r = sqrt(noise(i + 49))
            l.fill(ellipse(cos(a) * r * 94, sin(a) * r * 56, 2 + noise(i) * 4, 1.6), with: .color(Color(hex: 0x713E2D).opacity(0.4)))
        }
    }
    private func drawEgg(_ c: inout GraphicsContext, at center: CGPoint, angle: Double) {
        var l = c
        l.translateBy(x: center.x, y: center.y); l.rotate(by: .radians(angle))
        l.drawLayer { s in
            s.addFilter(.shadow(color: Color(hex: 0x442E16).opacity(0.5), radius: 12, x: 0, y: 8))
            s.fill(ellipse(-92, -121, 184, 242), with: .color(Color(hex: 0xA68A58)))
        }
        l.fill(ellipse(-88, -117, 176, 233), with: .linearGradient(Gradient(colors: [.white, Color(hex: 0xF7ECCE), Color(hex: 0xD5C9A3)]), startPoint: .init(x: -50, y: -70), endPoint: .init(x: 80, y: 120)))
        l.fill(ellipse(-65, -58, 132, 147), with: .color(Color(hex: 0xF3B831)))
        l.fill(ellipse(-57, -50, 114, 127), with: .radialGradient(Gradient(colors: [Color(hex: 0xFFB20F), Color(hex: 0xE68108), Color(hex: 0xE8A222)]), center: .init(x: -10, y: 0), startRadius: 1, endRadius: 80))
        for i in 0..<30 {
            let a = Double(i) / 30 * .pi * 2
            l.fill(ellipse(cos(a) * 58 - 3, sin(a) * 65 + 12, 7, 8), with: .color(Color(hex: 0xFFD35A).opacity(0.55)))
        }
        l.fill(ellipse(-35, -30, 34, 14), with: .color(Color(hex: 0xFFE694).opacity(0.72)))
        l.fill(ellipse(-43, -11, 10, 8), with: .color(.white.opacity(0.52)))
    }
    private func drawScallions(_ c: inout GraphicsContext) {
        for i in 0..<33 {
            let x = 440 + (noise(i * 2 + 8) - 0.5) * 188
            let y = 225 + (noise(i * 2 + 77) - 0.5) * 108
            var l = c
            l.translateBy(x: x, y: y); l.rotate(by: .radians(noise(i + 1) * 6))
            let w = 17 + noise(i + 55) * 13
            l.fill(ellipse(-w / 2, -9, w, 18), with: .color(Color(hex: 0x28442A).opacity(0.4)))
            l.stroke(ellipse(-w / 2, -10, w, 17), with: .color(i % 3 == 0 ? Color(hex: 0xD0DC85) : Color(hex: 0x70924A)), lineWidth: 5)
            l.stroke(ellipse(-w / 2 + 2, -8, w - 4, 13), with: .color(Color(hex: 0xDDE6A3).opacity(0.6)), lineWidth: 1.5)
        }
    }
    private func noise(_ n: Int) -> Double {
        let x = sin(Double(n + 1) * 127.1) * 43758.5453
        return x - floor(x)
    }
}
