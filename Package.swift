// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ID3Engine",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ID3Engine", targets: ["ID3Engine"])
    ],
    dependencies: [
        .package(url: "https://github.com/sbooth/CXXTagLib", from: "2.3.2")
    ],
    targets: [
        .target(
            name: "CID3Engine",
            dependencies: [
                .product(name: "taglib", package: "CXXTagLib")
            ],
            path: "ID3Engine/Sources/CID3Engine",
            publicHeadersPath: "include"
        ),
        .target(
            name: "ID3Engine",
            dependencies: ["CID3Engine"],
            path: "ID3Engine/Sources/ID3Engine"
        ),
        .testTarget(
            name: "ID3EngineTests",
            dependencies: ["ID3Engine"],
            path: "ID3Engine/Tests/ID3EngineTests",
            resources: [.copy("Fixtures")]
        )
    ],
    cxxLanguageStandard: .cxx17
)
