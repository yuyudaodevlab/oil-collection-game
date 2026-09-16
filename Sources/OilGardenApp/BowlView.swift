import SwiftUI
#if canImport(OilGardenCore)
import OilGardenCore
#endif

struct BowlView: View {
    @ObservedObject var session: GameSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragging = false
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                RamenArt(broth: session.broth).equatable()
                Canvas { context, size in
                    let scale = min(size.width, size.height)
                    let radius = scale * 0.39
                    let center = CGPoint(x: scale / 2, y: scale / 2)
                    func point(_ p: Vector) -> CGPoint { .init(x: center.x + p.x * radius, y: center.y + p.y * radius) }
                    context.clip(to: Path(ellipseIn: CGRect(x: scale * 0.11, y: scale * 0.11, width: scale * 0.78, height: scale * 0.78)))
                    // Soft bridges make nearby oil pearls read as a continuous liquid surface.
                    #if !os(watchOS)
                    context.drawLayer { liquid in
                        liquid.addFilter(.alphaThreshold(min: 0.42, color: session.broth.oil.opacity(0.48)))
                        liquid.addFilter(.blur(radius: scale * 0.007))
                        for drop in session.world.drops {
                            let p = point(drop.position), r = drop.radius * radius
                            liquid.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(.white))
                        }
                    }
                    #endif
                    for drop in session.world.drops {
                        let p = point(drop.position)
                        let r = drop.radius * radius
                        let wobble = reduceMotion ? 0 : sin(session.world.time * 2 + drop.phase) * 0.035
                        let rect = CGRect(x: p.x - r * (1 + wobble), y: p.y - r * (1 - wobble), width: r * 2 * (1 + wobble), height: r * 2 * (1 - wobble))
                        let path = Path(ellipseIn: rect)
                        context.fill(path, with: .radialGradient(Gradient(stops: [
                            .init(color: session.broth.oil.opacity(0.12), location: 0),
                            .init(color: session.broth.oil.opacity(0.28), location: 0.70),
                            .init(color: session.broth.oil.opacity(0.65), location: 0.96),
                            .init(color: session.broth.dark.opacity(0.8), location: 1)]),
                            center: p, startRadius: 0, endRadius: r))
                        context.stroke(path, with: .color(Color(hex: 0xFFE9A6).opacity(0.85)), lineWidth: max(0.6, scale * 0.0015))
                        var highlight = Path()
                        highlight.addArc(center: p, radius: r * 0.80, startAngle: .degrees(205), endAngle: .degrees(276), clockwise: false)
                        context.stroke(highlight, with: .color(.white.opacity(0.78)), style: StrokeStyle(lineWidth: max(0.8, r * 0.08), lineCap: .round))
                        context.fill(Path(ellipseIn: CGRect(x: p.x - r * 0.39, y: p.y - r * 0.48, width: r * 0.2, height: r * 0.1)), with: .color(.white.opacity(0.5)))
                    }
                    for ripple in session.ripples {
                        let age = session.world.time - ripple.born
                        let lifetime = ripple.bloom ? 2.2 : 1.1
                        let progress = age / lifetime
                        let r = radius * ((ripple.bloom ? 0.22 : 0.04) + progress * 0.18)
                        let p = point(ripple.position)
                        context.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                                       with: .color(Color.paper.opacity((1 - progress) * 0.42)), lineWidth: 1)
                    }
                }
                chopsticks(side: side)
            }
            .frame(width: side, height: side)
            .contentShape(Circle().inset(by: side * 0.10))
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = Vector((value.location.x / side - 0.5) / 0.39, (value.location.y / side - 0.5) / 0.39)
                    if !dragging { dragging = true; session.begin(point) }
                    session.move(point)
                }
                .onEnded { value in
                    dragging = false
                    let isTap = hypot(value.translation.width, value.translation.height) < 6
                    if isTap {
                        // A tap gives the same relaxed motion as the large one-touch button.
                        session.gather()
                    } else { session.end() }
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(session.broth.name)ラーメンの油")
            .accessibilityValue("ゆっくり漂っています")
            .accessibilityHint("ダブルタップで油が集まります。指でなぞっても遊べます。")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { session.gather() }
            .accessibilityAction(named: Text("油を寄せる")) { session.gather() }
            .onDisappear { dragging = false; session.end() }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func chopsticks(side: Double) -> some View {
        Canvas { c, _ in
            let active = session.world.target != nil
            let target = session.world.target ?? Vector(0.40, 0.37)
            let tip = CGPoint(x: side * (0.5 + target.x * 0.39), y: side * (0.5 + target.y * 0.39))
            let gap = side * (active ? 0.018 : 0.03)
            for index in 0..<2 {
                let offset = Double(index) * gap
                let end = CGPoint(x: side * 0.93 + offset, y: side * 0.99 - offset * 0.3)
                let start = CGPoint(x: tip.x + offset, y: tip.y - offset * 0.4)
                var stick = Path()
                stick.move(to: .init(x: start.x - side * 0.0025, y: start.y))
                stick.addLine(to: .init(x: end.x - side * 0.010, y: end.y))
                stick.addLine(to: .init(x: end.x + side * 0.010, y: end.y - side * 0.009))
                stick.addLine(to: .init(x: start.x + side * 0.004, y: start.y - side * 0.004))
                stick.closeSubpath()
                c.drawLayer { shadow in
                    shadow.addFilter(.shadow(color: .black.opacity(0.32), radius: side * 0.008, x: side * 0.006, y: side * 0.012))
                    shadow.fill(stick, with: .linearGradient(Gradient(colors: [Color(hex: 0xEAC28A), Color(hex: 0x9F6539), Color(hex: 0x412C21)]), startPoint: start, endPoint: end))
                }
                var grain = Path(); grain.move(to: start); grain.addLine(to: end)
                c.stroke(grain, with: .color(Color(hex: 0xF3CE95).opacity(0.55)), lineWidth: side * 0.002)
                for j in 0..<3 {
                    let t = 0.77 + Double(j) * 0.025
                    let p = CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
                    var band = Path(); band.move(to: .init(x: p.x - side * 0.006, y: p.y + side * 0.004))
                    band.addLine(to: .init(x: p.x + side * 0.006, y: p.y - side * 0.005))
                    c.stroke(band, with: .color(Color.gold.opacity(0.85)), lineWidth: side * 0.003)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
