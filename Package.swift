// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EthernetMenuBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "EthernetMenuBar", targets: ["EthernetMenuBar"])
    ],
    targets: [
        .executableTarget(name: "EthernetMenuBar"),
        .testTarget(name: "EthernetMenuBarTests", dependencies: ["EthernetMenuBar"])
    ]
)
