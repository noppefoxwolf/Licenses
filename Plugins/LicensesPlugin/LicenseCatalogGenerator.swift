import Foundation
import PackagePlugin

enum LicenseCatalogGenerator {
    static func makeBuildCommands(outputDirectory: URL, entries: [LicenseEntry]) throws -> [Command] {
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
}

private extension String {
    func indented(by spaces: Int) -> String {
        let prefix = String(repeating: " ", count: spaces)
        return split(separator: "\n", omittingEmptySubsequences: false)
            .map { prefix + $0 }
            .joined(separator: "\n")
    }
}
