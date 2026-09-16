// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OilGarden",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10)],
    products: [.library(name: "OilGardenCore", targets: ["OilGardenCore"]),
               .executable(name: "OilGarden", targets: ["OilGardenApp"])],
    targets: [.target(name: "OilGardenCore"),
              .executableTarget(name: "OilGardenApp", dependencies: ["OilGardenCore"]),
              .testTarget(name: "OilGardenCoreTests", dependencies: ["OilGardenCore"])])
