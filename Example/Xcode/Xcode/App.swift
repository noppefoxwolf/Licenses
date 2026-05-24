import Algorithms
import SwiftUI

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        List {
            ForEach(LicenseCatalog.licenses) { license in
                LicenseSection(license: license)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Licenses")
    }
}

struct LicenseSection: View {
    let license: LicenseCatalog.License

    var body: some View {
        NavigationLink(
            destination: {
                Group {
                    if let licenseText = license.licenseText {
                        ScrollView(.vertical) {
                            Text(licenseText)
                        }
                        .multilineTextAlignment(.leading)
                        .font(.caption2)
                        .monospaced()
                    } else {
                        ContentUnavailableView("Unknown License", systemImage: "questionmark.app.dashed")
                    }
                }
                .navigationTitle(license.name)
                .navigationSubtitle(license.repositoryURL ?? "")
                .navigationBarTitleDisplayMode(.inline)
            },
            label: {
                LabeledContent(
                    content: {
                        Text(license.displayVersion ?? "")
                    },
                    label: {
                        Text(license.name)
                            .font(.headline)
                    }
                )
            }
        )
    }
}
