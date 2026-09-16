import Foundation

public struct Vector: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public static let zero = Vector(0, 0)
    public static func + (a: Self, b: Self) -> Self { .init(a.x + b.x, a.y + b.y) }
    public static func - (a: Self, b: Self) -> Self { .init(a.x - b.x, a.y - b.y) }
    public static func * (a: Self, b: Double) -> Self { .init(a.x * b, a.y * b) }
    public var length: Double { hypot(x, y) }
    public func limited(_ length: Double) -> Self {
        self.length > length ? self * (length / max(self.length, 0.00001)) : self
    }
}

public struct OilDrop: Codable, Identifiable, Sendable {
    public var id: Int
    public var position: Vector
    public var velocity: Vector
    /// Radius in a bowl whose soup radius is 1.
    public var radius: Double
    public var phase: Double
    public init(id: Int, position: Vector, radius: Double, velocity: Vector = .zero, phase: Double = 0) {
        self.id = id; self.position = position; self.radius = radius
        self.velocity = velocity; self.phase = phase
    }
}

public struct MergeEvent: Sendable {
    public var position: Vector
    public var radius: Double
    public var isBloom: Bool
}

/// Fixed-size, normalized simulation shared by phone, desktop and watch.
/// There is no countdown, failure state, or offline progress to catch up on.
public struct OilWorld: Sendable {
    public private(set) var drops: [OilDrop]
    public private(set) var time: Double = 0
    public private(set) var selectedID: Int?
    public private(set) var target: Vector?
    private var nextID: Int
    private var seed: UInt64
    private var replenishClock = 0.0
    private var tapRemaining = 0.0
    private var crownAngle = 0.0
    public var reducedMotion = false
    public var replenishes = true

    public init(seed: UInt64 = 42, drops: [OilDrop]? = nil, count: Int = 28) {
        self.seed = seed
        self.drops = drops ?? []
        self.nextID = (drops?.map(\.id).max() ?? -1) + 1
        if drops == nil { for _ in 0..<max(1, min(count, 40)) { spawn() } }
    }

    private mutating func random() -> Double {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return Double(seed >> 11) / Double(UInt64.max >> 11)
    }

    private mutating func spawn() {
        let angle = random() * .pi * 2
        let distance = sqrt(random()) * 0.82
        let radius = 0.025 + random() * 0.045
        drops.append(OilDrop(id: nextID, position: .init(cos(angle) * distance, sin(angle) * distance),
                             radius: radius, phase: random() * .pi * 2))
        nextID += 1
    }

    public mutating func begin(at point: Vector) {
        target = point.limited(0.9)
        tapRemaining = 0
        selectedID = drops.min { ($0.position - target!).length < ($1.position - target!).length }?.id
    }

    public mutating func move(to point: Vector) { target = point.limited(0.9) }
    public mutating func end() { target = nil; selectedID = nil; tapRemaining = 0 }

    /// Accessible one-action gathering, also used by the Space key.
    public mutating func gather() {
        begin(at: .zero)
        tapRemaining = 2.8
    }

    /// The crown follows a small continuous orbit; no precise touch target is needed.
    public mutating func turnCrown(by amount: Double) {
        guard amount.isFinite else { return }
        crownAngle += amount * 1.8
        let point = Vector(cos(crownAngle) * 0.34, sin(crownAngle) * 0.34)
        if selectedID == nil { begin(at: point) } else { move(to: point) }
        tapRemaining = 1.6
    }

    @discardableResult public mutating func step(_ elapsed: Double) -> [MergeEvent] {
        guard elapsed.isFinite, elapsed > 0 else { return [] }
        let dt = min(elapsed, 1.0 / 20.0) // Never jump forward after backgrounding.
        time += dt
        if tapRemaining > 0 {
            tapRemaining -= dt
            if tapRemaining <= 0 { end() }
        }
        for i in drops.indices {
            let position = drops[i].position
            var force = Vector.zero
            if let target {
                let delta = target - position
                if drops[i].id == selectedID {
                    force = delta * 19
                } else if delta.length < 0.42 {
                    force = delta * 4.6
                }
            }
            if !reducedMotion {
                force = force + Vector(sin(time * 0.27 + drops[i].phase), cos(time * 0.21 + drops[i].phase)) * 0.014
            }
            drops[i].velocity = (drops[i].velocity + force * dt) * exp(-5.5 * dt)
            drops[i].position = (position + drops[i].velocity * dt).limited(max(0.1, 0.96 - drops[i].radius))
        }
        var events: [MergeEvent] = []
        var i = 0
        while i < drops.count {
            var j = i + 1
            while j < drops.count {
                let a = drops[i], b = drops[j]
                if (a.position - b.position).length < (a.radius + b.radius) * 0.93 {
                    let aArea = a.radius * a.radius, bArea = b.radius * b.radius
                    let sum = aArea + bArea
                    drops[i].position = (a.position * aArea + b.position * bArea) * (1 / sum)
                    drops[i].velocity = (a.velocity * aArea + b.velocity * bArea) * (1 / sum)
                    drops[i].radius = sqrt(sum)
                    if selectedID == b.id { selectedID = a.id }
                    drops.remove(at: j)
                    events.append(.init(position: drops[i].position, radius: drops[i].radius, isBloom: false))
                } else { j += 1 }
            }
            i += 1
        }
        // A large pearl gently dissolves into the broth, leaving room to play forever.
        for drop in drops where drop.radius > 0.235 {
            events.append(.init(position: drop.position, radius: drop.radius, isBloom: true))
            if selectedID == drop.id { selectedID = nil }
        }
        drops.removeAll { $0.radius > 0.235 }
        replenishClock += dt
        if replenishes && replenishClock >= 0.8 && drops.count < 28 {
            replenishClock = 0
            spawn()
        }
        return events
    }

    public var snapshot: Data? { try? JSONEncoder().encode(drops) }
    public static func restored(from data: Data?, seed: UInt64 = 42) -> OilWorld {
        guard let data, let drops = try? JSONDecoder().decode([OilDrop].self, from: data),
              !drops.isEmpty, drops.count <= 40,
              Set(drops.map(\.id)).count == drops.count,
              drops.allSatisfy({ $0.id >= 0 && $0.id < 1_000_000_000 && $0.radius.isFinite && $0.radius > 0 && $0.radius <= 0.235 &&
                  $0.position.x.isFinite && $0.position.y.isFinite && $0.position.length <= 1 &&
                  $0.velocity.x.isFinite && $0.velocity.y.isFinite && $0.velocity.length < 10 && $0.phase.isFinite })
        else { return OilWorld(seed: seed) }
        return OilWorld(seed: seed, drops: drops.map {
            var resting = $0; resting.velocity = .zero; return resting
        })
    }
}
