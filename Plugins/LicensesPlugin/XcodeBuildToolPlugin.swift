import Foundation
import PackagePlugin
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension LicensesPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let entries = target.recursiveDependencyLicenseEntries()
        return try LicenseCatalogGenerator.makeBuildCommands(
            outputDirectory: context.pluginWorkDirectoryURL.appending(path: "Generated"),
            entries: entries.isEmpty
                ? context.xcodeProject.resolvedPackageLicenseEntries(
                    checkoutsDirectory: context.pluginWorkDirectoryURL.sourcePackagesCheckoutsDirectory
                )
                : entries
        )
    }
}

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

private extension XcodeProject {
    func resolvedPackageLicenseEntries(checkoutsDirectory: URL) -> [LicenseEntry] {
        directoryURL.packageResolvedPins.map { pin in
            let packageDirectory = checkoutsDirectory
                .appending(path: pin.location.lastPathComponentWithoutGitSuffix)

            return LicenseEntry(
                id: pin.identity,
                name: pin.location.lastPathComponentWithoutGitSuffix,
                licenseText: packageDirectory.licenseText,
                displayVersion: pin.state.version,
                repositoryURL: pin.location
            )
        }
    }
}

private extension URL {
    var packageResolvedPins: [PackageResolved.Pin] {
        let resolvedURLs = [
            appending(path: "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
            appending(path: "\(lastPathComponent).xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
        ]

        for resolvedURL in resolvedURLs {
            guard
                let data = try? Data(contentsOf: resolvedURL),
                let packageResolved = try? JSONDecoder().decode(PackageResolved.self, from: data)
            else {
                continue
            }

            return packageResolved.pins
        }

        return []
    }

    var sourcePackagesCheckoutsDirectory: URL {
        let components = pathComponents

        guard
            let buildIndex = components.firstIndex(of: "Build"),
            buildIndex >= 1
        else {
            return deletingLastPathComponent().appending(path: "SourcePackages/checkouts")
        }

        return URL(fileURLWithPath: components[..<buildIndex].joined(separator: "/"))
            .appending(path: "SourcePackages/checkouts")
    }
}

private struct PackageResolved: Decodable {
    let pins: [Pin]

    struct Pin: Decodable {
        let identity: String
        let location: String
        let state: State
    }

    struct State: Decodable {
        let version: String?
    }
}

private extension String {
    var lastPathComponentWithoutGitSuffix: String {
        URL(string: self)?.lastPathComponent.replacingOccurrences(of: ".git", with: "")
            ?? split(separator: "/").last.map(String.init)?.replacingOccurrences(of: ".git", with: "")
            ?? self
    }
}
#endif
