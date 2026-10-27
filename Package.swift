// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Prelude",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "Prelude", targets: ["Prelude"]),
        .library(name: "PreludeLookup", targets: ["PreludeLookup"])
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
        .target(
            name: "PreludeLookup",
            dependencies: ["Prelude"],
            path: "Prelude/Sources/PreludeLookup"
        ),
        .testTarget(
            name: "PreludeTests",
            dependencies: ["Prelude"],
            path: "Prelude/Tests/PreludeTests",
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "PreludeLookupTests",
            dependencies: ["PreludeLookup"],
            path: "Prelude/Tests/PreludeLookupTests"
        )
    ],
    cxxLanguageStandard: .cxx17
)
