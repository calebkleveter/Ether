// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Ether",
    dependencies: [
        .package(url: "https://github.com/vapor/console.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0-rc")
    ],
    targets: [
        .target(name: "GitHub", dependencies: ["Core"]),
        .target(name: "Helpers", dependencies: ["Core", "Console"]),
        .target(name: "Ether", dependencies: ["Helpers", "Console"]),
        .target(name: "Executable", dependencies: ["Ether", "Console"])
    ]
)
