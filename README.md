# Licenses

Licenses is a Swift Package Manager build tool plugin that generates a license catalog for your package dependencies.

The plugin scans recursive package dependencies at build time and generates a `LicenseCatalog` type containing each dependency's name, version, repository URL, and license text when a license file is available.

## Requirements

- Swift 6.3 or later
- Swift Package Manager

## Installation

Add this package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/noppefoxwolf/Licenses.git", from: "0.1.0"),
]
```

Then attach `LicensesPlugin` to the target that needs access to the generated catalog:

```swift
targets: [
    .executableTarget(
        name: "AppModule",
        dependencies: [
            // Your dependencies
        ],
        plugins: [
            .plugin(name: "LicensesPlugin", package: "Licenses")
        ]
    )
]
```

For local development, you can use a path dependency:

```swift
dependencies: [
    .package(name: "Licenses", path: "../Licenses"),
]
```

## Usage

After the plugin runs, it generates a public `LicenseCatalog` enum in your target.

```swift
for license in LicenseCatalog.licenses {
    print(license.name)
    print(license.displayVersion ?? "No version")
    print(license.repositoryURL ?? "No repository URL")
    print(license.licenseText ?? "No license text")
}
```

The generated license model is:

```swift
public enum LicenseCatalog {
    public struct License: Identifiable, Equatable, Hashable, Sendable {
        public let id: String
        public let name: String
        public let licenseText: String?
        public let displayVersion: String?
        public let repositoryURL: String?
    }

    public static var licenses: [License]
}
```

## SwiftUI Example

```swift
import SwiftUI

struct LicensesView: View {
    var body: some View {
        List(LicenseCatalog.licenses) { license in
            NavigationLink(license.name) {
                ScrollView {
                    Text(license.licenseText ?? "Unknown License")
                        .font(.caption)
                        .monospaced()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle(license.name)
            }
        }
        .navigationTitle("Licenses")
    }
}
```

See `Example.swiftpm` for a working sample app.

## License File Detection

The plugin reads the first matching file from each dependency package directory:

- `LICENSE`
- `LICENSE.md`
- `LICENSE.txt`
- `LICENCE`
- `LICENCE.md`
- `LICENCE.txt`

If no license file is found, `licenseText` is `nil`.

## License

Licenses is available under the MIT license. See `LICENSE` for details.
