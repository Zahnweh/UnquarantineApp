// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnquarantineApp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "UnquarantineApp",
            path: "Sources/UnquarantineApp"
        )
    ]
)
