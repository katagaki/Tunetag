//
//  Dependency.swift
//  Tunetag
//

import Foundation

struct Dependency: Identifiable, Hashable, Decodable {
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
