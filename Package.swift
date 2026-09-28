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
                "Resources/Assets.xcassets"
            ],
            resources: [
                .process("Resources/Presets")
            ]
        )
    ]
)
