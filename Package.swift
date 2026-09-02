// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Matuta",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MatutaCore", targets: ["MatutaCore"]),
        .executable(name: "Matuta", targets: ["Matuta"]),
    ],
    targets: [
        .target(name: "MatutaCore"),
        .executableTarget(name: "Matuta", dependencies: ["MatutaCore"]),
        .testTarget(name: "MatutaCoreTests", dependencies: ["MatutaCore"]),
    ]
)
