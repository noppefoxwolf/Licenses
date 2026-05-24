import Foundation
import PackagePlugin

@main
struct LicensesPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let outputDirectory = context.pluginWorkDirectoryURL.appending(path: "Generated")
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let outputFile = outputDirectory.appending(path: "GeneratedLicenseCatalogSymbols.swift")
        let licenses = context.package.recursiveDependencies()
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
            .map { $0.generatedLicenseEntry }
            .joined(separator: ",\n")

        let source = """
            public enum LicenseCatalog {
                public struct License: Identifiable, Equatable, Hashable, Sendable {
                    public let id: String
                    public let name: String
                    public let licenseText: String?
                    public let originURL: String?
                }

                public static var licenses: [License] {
                    [
            \(licenses.indented(by: 12))
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

private extension Package {
    var generatedLicenseEntry: String {
        """
        License(
            id: \(String(reflecting: id)),
            name: \(String(reflecting: displayName)),
            licenseText: \(licenseText.map { String(reflecting: $0) } ?? "nil"),
            originURL: \(originURL.map { String(reflecting: $0) } ?? "nil")
        )
        """
    }

    var originURL: String? {
        switch origin {
        case let .repository(url, _, _):
            url
        default:
            nil
        }
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
            let licenseURL = directoryURL.appending(path: fileName)
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
