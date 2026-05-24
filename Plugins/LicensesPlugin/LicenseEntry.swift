struct LicenseEntry {
    let id: String
    let name: String
    let licenseText: String?
    let displayVersion: String?
    let repositoryURL: String?
}

extension LicenseEntry {
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
