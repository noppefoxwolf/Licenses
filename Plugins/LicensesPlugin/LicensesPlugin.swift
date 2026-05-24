import Foundation
import PackagePlugin
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

@main
struct LicensesPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        try makeBuildCommands(
            outputDirectory: context.pluginWorkDirectoryURL.appending(path: "Generated"),
            entries: context.package.recursiveDependencies().map(\.licenseEntry)
        )
    }
}

#if canImport(XcodeProjectPlugin)
extension LicensesPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        try makeBuildCommands(
            outputDirectory: context.pluginWorkDirectoryURL.appending(path: "Generated"),
            entries: target.recursiveDependencyLicenseEntries()
        )
    }
}
#endif

private func makeBuildCommands(outputDirectory: URL, entries: [LicenseEntry]) throws -> [Command] {
    try FileManager.default.createDirectory(
        at: outputDirectory,
        withIntermediateDirectories: true
    )

    let outputFile = outputDirectory.appending(path: "GeneratedLicenseCatalogSymbols.swift")
    let licenses = entries
        .sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        .map(\.generatedSource)
        .joined(separator: ",\n")

    let source = """
        public enum LicenseCatalog {
            public struct License: Identifiable, Equatable, Hashable, Sendable {
                public let id: String
                public let name: String
                public let licenseText: String?
                public let displayVersion: String?
                public let repositoryURL: String?
            }

            public static var licenses: [License] {
                [
        \(licenses.indented(by: 8))
                ]
            }
        }
        """

    try source.write(to: outputFile, atomically: true, encoding: String.Encoding.utf8)

    return [
        .prebuildCommand(
            displayName: "Generate license catalog",
            executable: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: [],
            outputFilesDirectory: outputDirectory
        )
    ]
}

private extension Package {
    func recursiveDependencies() -> [Package] {
        var visitedIDs = Set<String>()
        var collectedDependencies: [Package] = []

        func collect(_ dependencies: [PackageDependency]) {
            for dependency in dependencies {
                let package = dependency.package
                guard visitedIDs.insert(package.id).inserted else {
                    continue
                }
                collectedDependencies.append(package)
                collect(package.dependencies)
            }
        }

        collect(dependencies)
        return collectedDependencies
    }
}

private struct LicenseEntry {
    let id: String
    let name: String
    let licenseText: String?
    let displayVersion: String?
    let repositoryURL: String?
}

private extension LicenseEntry {
    var generatedSource: String {
        """
        License(
            id: \(String(reflecting: id)),
            name: \(String(reflecting: name)),
            licenseText: \(licenseText.map { String(reflecting: $0) } ?? "nil"),
            displayVersion: \(displayVersion.map { String(reflecting: $0) } ?? "nil"),
            repositoryURL: \(repositoryURL.map { String(reflecting: $0) } ?? "nil"),
        )
        """
    }
}

private extension Package {
    var licenseEntry: LicenseEntry {
        LicenseEntry(
            id: id,
            name: displayName,
            licenseText: directoryURL.licenseText,
            displayVersion: displayVersion,
            repositoryURL: repositoryURL
        )
    }

    var displayVersion: String? {
        switch origin {
        case .registry(_, let displayVersion), .repository(_, let displayVersion, _):
            displayVersion
        case .local, .root:
            nil
        @unknown default:
            nil
        }
    }

    var repositoryURL: String? {
        switch origin {
        case let .repository(url, _, _):
            url
        default:
            nil
        }
    }
}

#if canImport(XcodeProjectPlugin)
private extension XcodeTarget {
    func recursiveDependencyLicenseEntries() -> [LicenseEntry] {
        var visitedTargetIDs = Set<String>()
        var visitedProductIDs = Set<String>()
        var entries: [LicenseEntry] = []

        func collect(_ target: XcodeTarget) {
            guard visitedTargetIDs.insert(target.id).inserted else {
                return
            }

            for dependency in target.dependencies {
                switch dependency {
                case .target(let target):
                    collect(target)
                case .product(let product):
                    guard visitedProductIDs.insert(product.id).inserted else {
                        continue
                    }
                    entries.append(product.licenseEntry)
                @unknown default:
                    continue
                }
            }
        }

        collect(self)
        return entries
    }
}

private extension Product {
    var licenseEntry: LicenseEntry {
        let packageDirectory = targets.compactMap { $0.directoryURL.packageDirectory }.first
        return LicenseEntry(
            id: id,
            name: name,
            licenseText: packageDirectory?.licenseText,
            displayVersion: nil,
            repositoryURL: nil
        )
    }
}
#endif

private extension URL {
    var packageDirectory: URL? {
        var directory = self

        while directory.path != directory.deletingLastPathComponent().path {
            if FileManager.default.fileExists(atPath: directory.appending(path: "Package.swift").path) {
                return directory
            }
            if directory.licenseText != nil {
                return directory
            }
            directory.deleteLastPathComponent()
        }

        return nil
    }

    var licenseText: String? {
        let licenseFileNames = [
            "LICENSE",
            "LICENSE.md",
            "LICENSE.txt",
            "LICENCE",
            "LICENCE.md",
            "LICENCE.txt",
        ]

        for fileName in licenseFileNames {
            let licenseURL = appending(path: fileName)
            if let text = try? String(contentsOf: licenseURL, encoding: String.Encoding.utf8) {
                return text
            }
        }

        return nil
    }
}

private extension String {
    func indented(by spaces: Int) -> String {
        let prefix = String(repeating: " ", count: spaces)
        return split(separator: "\n", omittingEmptySubsequences: false)
            .map { prefix + $0 }
            .joined(separator: "\n")
    }
}
