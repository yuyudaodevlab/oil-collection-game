import SwiftUI
#if canImport(OilGardenCore)
import OilGardenCore
#endif
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif
#if !os(watchOS)
import AVFoundation
#endif

struct Ripple: Identifiable {
    let id = UUID()
    let position: Vector
    let born: Double
    let bloom: Bool
}

@MainActor
final class GameSession: ObservableObject {
    @Published var world: OilWorld
    @Published var ripples: [Ripple] = []
    @Published var message = "油を、そっと寄せてみて。"
    @Published var merges: Int
    @Published var blooms: Int
    @Published var broth: Broth { didSet { defaults.set(broth.rawValue, forKey: "broth") } }
    @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics") } }
    @Published var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }
    private let defaults: UserDefaults
    private var lastFeedback = -10.0
    private var lastSave = 0.0
    private var messageUntil = 0.0
    private var interactive = false
    #if !os(watchOS)
    private var player: AVAudioPlayer?
    #endif

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        world = .restored(from: defaults.data(forKey: "oil.snapshot"), seed: UInt64.random(in: 1...1_000_000))
        merges = max(0, defaults.integer(forKey: "merges"))
        blooms = max(0, defaults.integer(forKey: "blooms"))
        broth = Broth(rawValue: defaults.string(forKey: "broth") ?? "") ?? .shoyu
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
        sound = defaults.bool(forKey: "sound")
    }

    func tick(_ dt: Double, reducedMotion: Bool) {
        world.reducedMotion = reducedMotion
        let events = world.step(dt)
        for event in events {
            // Idle overlaps do not earn keepsakes or make unsolicited sounds.
            if interactive {
                if event.isBloom { blooms += 1 } else { merges += 1 }
                if let keepsake = Keepsake.all.first(where: { $0.needed == merges }), !event.isBloom {
                    message = "「\(keepsake.name)」を、思い出に。"
                    messageUntil = world.time + 4
                } else if event.isBloom {
                    message = "まあるくなって、スープにとけた。"
                    messageUntil = world.time + 4
                }
                feedback(bloom: event.isBloom)
            }
            if !reducedMotion && ripples.count < 12 {
                ripples.append(Ripple(position: event.position, born: world.time, bloom: event.isBloom))
            }
        }
        ripples.removeAll { world.time - $0.born > ($0.bloom ? 2.2 : 1.1) }
        if world.target == nil { interactive = false }
        if world.time > messageUntil && messageUntil > 0 {
            message = "急がなくて、だいじょうぶ。"
            messageUntil = 0
        }
        if world.time - lastSave > 8 { save(); lastSave = world.time }
    }

    func begin(_ point: Vector) { interactive = true; world.begin(at: point) }
    func move(_ point: Vector) { world.move(to: point) }
    func end() { world.end(); interactive = false; save() }
    func gather() { interactive = true; world.gather() }
    func crown(_ delta: Double) { interactive = true; world.turnCrown(by: delta) }
    func save() {
        defaults.set(world.snapshot, forKey: "oil.snapshot")
        defaults.set(merges, forKey: "merges")
        defaults.set(blooms, forKey: "blooms")
    }

    private func feedback(bloom: Bool) {
        guard world.time - lastFeedback > (bloom ? 0.15 : 0.22) else { return }
        lastFeedback = world.time
        if haptics {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: bloom ? 0.65 : 0.32)
            #elseif os(watchOS)
            // Avoid repeated wrist taps during a single sweep.
            if bloom { WKInterfaceDevice.current().play(.click) }
            #elseif os(macOS)
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            #endif
        }
        #if !os(watchOS)
        if sound { playPlop(bloom: bloom) }
        #endif
    }

    #if !os(watchOS)
    /// A quiet synthesized water note. No assets, downloads, or microphone access.
    private func playPlop(bloom: Bool) {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        #endif
        let rate = 22050, count = 4200
        var bytes = Data()
        func word(_ value: UInt32, _ width: Int) {
            for offset in 0..<width { bytes.append(UInt8((value >> (offset * 8)) & 255)) }
        }
        bytes.append(contentsOf: Array("RIFF".utf8)); word(UInt32(36 + count * 2), 4)
        bytes.append(contentsOf: Array("WAVEfmt ".utf8)); word(16, 4); word(1, 2); word(1, 2)
        word(UInt32(rate), 4); word(UInt32(rate * 2), 4); word(2, 2); word(16, 2)
        bytes.append(contentsOf: Array("data".utf8)); word(UInt32(count * 2), 4)
        for i in 0..<count {
            let t = Double(i) / Double(rate)
            let frequency = bloom ? 430.0 : 660.0
            let envelope = min(t * 300, 1) * exp(-t * 32)
            let wave = sin(2 * .pi * frequency * (t - 0.7 * t * t)) * envelope
            let sample = Int16(wave * 4200)
            word(UInt32(UInt16(bitPattern: sample)), 2)
        }
        player = try? AVAudioPlayer(data: bytes)
        player?.play()
    }
    #endif
}
