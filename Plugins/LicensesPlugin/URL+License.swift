import Foundation

extension URL {
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
