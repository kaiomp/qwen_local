// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "QwenLocal",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "QwenLocal"),
        .testTarget(name: "QwenLocalTests", dependencies: ["QwenLocal"]),
    ]
)
