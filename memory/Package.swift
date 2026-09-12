// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VisionRecallMemory",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "VisionRecallMemory", targets: ["VisionRecallMemory"])
    ],
    targets: [
        .target(name: "VisionRecallMemory"),
        .testTarget(name: "VisionRecallMemoryTests", dependencies: ["VisionRecallMemory"]),
        .testTarget(
            name: "VisionRecallMemoryIntegrationTests",
            dependencies: ["VisionRecallMemory"]
        )
    ]
)
