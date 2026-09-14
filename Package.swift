// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EthernetMenuBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "EthernetMenuBar", targets: ["EthernetMenuBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.6")
    ],
    targets: [
        .executableTarget(
            name: "EthernetMenuBar",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        ),
        .testTarget(name: "EthernetMenuBarTests", dependencies: ["EthernetMenuBar"])
    ]
)
