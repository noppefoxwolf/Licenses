// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Licenses",
    products: [
        .plugin(
            name: "LicensesPlugin",
            targets: ["LicensesPlugin"]
        ),
    ],
    targets: [
        .plugin(
            name: "LicensesPlugin",
            capability: .buildTool()
        ),
    ],
    swiftLanguageModes: [.v6]
)
