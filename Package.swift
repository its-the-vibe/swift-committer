// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-committer",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "swift-committer",
            path: "Sources/swift-committer"
        )
    ]
)
