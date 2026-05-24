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

    @State
    var isExpanded: Bool = false

    let license: LicenseCatalog.License

    var body: some View {
        Section(license.name + (license.originURL ?? "a"), isExpanded: $isExpanded) {
            Text(license.licenseText ?? "")
                .multilineTextAlignment(.leading)
                .font(.caption2)
                .monospaced()
        }
    }
}
