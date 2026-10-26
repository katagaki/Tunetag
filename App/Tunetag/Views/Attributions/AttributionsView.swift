//
//  AttributionsView.swift
//  Tunetag
//

import SwiftUI

struct AttributionsView: View {

    @Environment(\.dismiss) var dismiss
    private let dependencies: [Dependency] = Dependency.loadAll()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(destination: URL(string: "https://github.com/katagaki/Tunetag")!) {
                        HStack {
                            Text(verbatim: "katagaki/Tunetag")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "More.GitHub")
                }
                ForEach(dependencies) { dependency in
                    Section {
                        DisclosureGroup("Attributions.License") {
                            Text(dependency.licenseText)
                                .font(.caption)
                                .monospaced()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } header: {
                        ListSectionHeader(text: dependency.displayName)
                    }
                }
            }
            .navigationTitle("More.Attributions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) {
                            dismiss()
                        }
                    } else {
                        Button("Shared.Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct Dependency: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let licenseText: String

    /// The name of the library itself, rather than the package that wraps it.
    var displayName: String {
        switch name {
        case "CXXTagLib": "TagLib"
        default: name
        }
    }

    static func loadAll() -> [Dependency] {
        guard let url = Bundle.main.url(forResource: "Licenses", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let wrapper = try? PropertyListDecoder().decode(Wrapper.self, from: data) else {
            return []
        }
        return wrapper.dependencies
    }

    private struct Wrapper: Decodable {
        let dependencies: [Dependency]
    }
}
