// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "InputRelay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "InputRelay",
            targets: ["InputRelay"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "InputRelay",
            dependencies: [],
            path: "InputRelay",
            exclude: [
                "Resources/Info.plist",
                "Resources/Assets.xcassets",
                "Resources/AppIcon.icns"
            ],
            resources: [
                .process("Resources/Presets")
            ]
        ),
        .testTarget(
            name: "InputRelayTests",
            dependencies: ["InputRelay"],
            path: "Tests/InputRelayTests"
        )
    ]
)
