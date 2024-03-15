// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "kaleidoscope",
    platforms: [.macOS(.v11)],
    products: [
        .executable(
            name: "kaleidoscope",
            targets: ["kaleidoscope"]),
    ],
    targets: [
        .executableTarget(
            name: "kaleidoscope",
            dependencies: ["cllvm"]
        ),
        .systemLibrary(
            name: "cllvm",
            pkgConfig: "cllvm"
        ),
    ]
)
