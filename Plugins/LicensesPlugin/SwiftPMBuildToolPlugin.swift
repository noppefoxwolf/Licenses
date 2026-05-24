import PackagePlugin

extension LicensesPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        try LicenseCatalogGenerator.makeBuildCommands(
            outputDirectory: context.pluginWorkDirectoryURL.appending(path: "Generated"),
            entries: context.package.recursiveDependencies().map(\.licenseEntry)
        )
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
