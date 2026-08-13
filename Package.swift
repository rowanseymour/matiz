// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Matiz",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MatizKit"),
        .executableTarget(
            name: "Matiz", dependencies: ["MatizKit"], resources: [.process("Resources")]),
        // Assert-based checks runnable with just CommandLineTools (no XCTest/Swift
        // Testing without full Xcode): `swift run matiz-tests`
        .executableTarget(name: "matiz-tests", dependencies: ["MatizKit"]),
    ]
)
