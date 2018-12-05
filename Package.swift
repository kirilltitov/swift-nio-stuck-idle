// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "nio-idle",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "1.8.0")),
    ],
    targets: [
        .target(name: "Client", dependencies: ["NIO"]),
        .target(name: "Server", dependencies: ["NIO"]),
    ]
)
