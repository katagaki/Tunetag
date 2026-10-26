//
//  MoreLicensesView.swift
//  Tunetag
//

import SwiftUI

struct MoreLicensesView: View {
    private let dependencies: [Dependency] = Dependency.loadAll()
    @State private var expanded: Set<String> = []

    var body: some View {
        List {
            ForEach(dependencies) { dependency in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expanded.contains(dependency.id) },
                        set: { isOn in
                            if isOn {
                                expanded.insert(dependency.id)
                            } else {
                                expanded.remove(dependency.id)
                            }
                        }
                    )
                ) {
                    Text(dependency.licenseText)
                        .font(.caption)
                        .monospaced()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text(dependency.name)
                        .monospaced()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("More.Attributions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct Dependency: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let licenseText: String

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
