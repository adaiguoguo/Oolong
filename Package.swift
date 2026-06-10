// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Oolong",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "Oolong",
            path: "Sources/Oolong"
        ),
        .testTarget(
            name: "OolongTests",
            dependencies: [
                "Oolong",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/OolongTests"
        )
    ]
)
