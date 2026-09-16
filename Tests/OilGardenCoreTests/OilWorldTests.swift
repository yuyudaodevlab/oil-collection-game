import XCTest
@testable import OilGardenCore

final class OilWorldTests: XCTestCase {
    func testMergeConservesAreaAndCenterOfMass() {
        var world = OilWorld(drops: [.init(id: 0, position: .init(-0.02, 0), radius: 0.08),
                                     .init(id: 1, position: .init(0.02, 0), radius: 0.06)])
        world.reducedMotion = true
        let events = world.step(1.0 / 30)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(world.drops.count, 1)
        XCTAssertEqual(world.drops[0].radius, 0.1, accuracy: 0.00001)
        XCTAssertEqual(world.drops[0].position.x, -0.0056, accuracy: 0.00001)
    }
    func testDraggingMovesOilAndReleaseStopsAttraction() {
        var world = OilWorld(drops: [.init(id: 7, position: .zero, radius: 0.05)])
        world.replenishes = false
        world.begin(at: .zero)
        world.move(to: .init(0.5, 0.2))
        for _ in 0..<90 { world.step(1.0 / 30) }
        XCTAssertGreaterThan(world.drops[0].position.x, 0.45)
        world.end()
        XCTAssertNil(world.target)
        XCTAssertNil(world.selectedID)
    }
    func testSelectionSurvivesMerge() {
        var world = OilWorld(drops: [.init(id: 0, position: .zero, radius: 0.06),
                                     .init(id: 1, position: .init(0.03, 0), radius: 0.06)])
        world.begin(at: .init(0.03, 0))
        world.step(1.0 / 30)
        XCTAssertEqual(world.selectedID, 0)
    }
    func testLongSessionRemainsFiniteBoundedAndPlayable() {
        var world = OilWorld(seed: 18)
        var blooms = 0
        for frame in 0..<30_000 {
            if frame % 100 == 0 { world.gather() }
            blooms += world.step(1.0 / 30).filter(\.isBloom).count
            XCTAssertLessThanOrEqual(world.drops.count, 40)
            XCTAssertTrue(world.drops.allSatisfy { $0.position.length <= 1 && $0.radius.isFinite })
        }
        XCTAssertGreaterThan(blooms, 0)
        XCTAssertFalse(world.drops.isEmpty)
    }
    func testSnapshotValidationAndRestoration() {
        let original = OilWorld(seed: 9)
        let restored = OilWorld.restored(from: original.snapshot)
        XCTAssertEqual(restored.drops.count, original.drops.count)
        XCTAssertEqual(restored.drops[0].position, original.drops[0].position)
        XCTAssertEqual(OilWorld.restored(from: Data("bad".utf8)).drops.count, 28)
        let invalid = OilWorld(drops: [.init(id: 0, position: .zero, radius: -2)])
        XCTAssertEqual(OilWorld.restored(from: invalid.snapshot).drops.count, 28)
    }
    func testCrownAndAccessibleGatherExpireWithoutTimerPressure() {
        var world = OilWorld()
        world.turnCrown(by: 0.4)
        XCTAssertNotNil(world.target)
        for _ in 0..<60 { world.step(1.0 / 30) }
        XCTAssertNil(world.target)
        world.gather()
        for _ in 0..<100 { world.step(1.0 / 30) }
        XCTAssertNil(world.target)
    }
    func testBackgroundGapIsClamped() {
        var world = OilWorld()
        world.step(60 * 60)
        XCTAssertEqual(world.time, 0.05, accuracy: 0.0001)
        world.step(.infinity)
        XCTAssertEqual(world.time, 0.05, accuracy: 0.0001)
    }
}
