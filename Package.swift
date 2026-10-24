// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BookAndQuill",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "BookCore"),
        .executableTarget(
            name: "BookAndQuill",
            dependencies: ["BookCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(name: "IconGen"),
        .testTarget(name: "BookCoreTests", dependencies: ["BookCore"]),
    ]
)
