// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Prelude",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "Prelude", targets: ["Prelude"])
    ],
    dependencies: [
        .package(url: "https://github.com/sbooth/CXXTagLib", from: "2.3.2")
    ],
    targets: [
        .target(
            name: "CPrelude",
            dependencies: [
                .product(name: "taglib", package: "CXXTagLib")
            ],
            path: "Prelude/Sources/CPrelude",
            publicHeadersPath: "include"
        ),
        .target(
            name: "Prelude",
            dependencies: ["CPrelude"],
            path: "Prelude/Sources/Prelude"
        ),
        .testTarget(
            name: "PreludeTests",
            dependencies: ["Prelude"],
            path: "Prelude/Tests/PreludeTests",
            resources: [.copy("Fixtures")]
        )
    ],
    cxxLanguageStandard: .cxx17
)
