// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Ether",
    products: [
        .executable(name: "Executable", targets: ["Executable"]),
        .library(name: "Ether", targets: ["Helpers", "Ether"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Xgen.git", from: "2.1.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.3"),
        .package(url: "https://github.com/vapor/console.git", from: "3.0.2"),
        .package(url: "https://github.com/vapor/core.git", from: "3.1.7"),
        .package(url: "https://github.com/Ether-CLI/Manifest.git", from: "0.4.4")
    ],
    targets: [
        .target(name: "Helpers", dependencies: ["Core", "Console"]),
        .target(name: "Ether", dependencies: ["Vapor", "Helpers", "Console", "Command", "Manifest", "Core", "Xgen"]),
        .target(name: "Executable", dependencies: ["Vapor", "Ether", "Console"]),
        .testTarget(name: "EtherTests", dependencies: ["Ether", "Executable"])
    ]
)
