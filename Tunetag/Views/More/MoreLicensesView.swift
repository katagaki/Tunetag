//
//  MoreLicensesView.swift
//  Tunetag
//

import SwiftUI

struct MoreLicensesView: View {
    var body: some View {
        List {
            ForEach(Dependency.all) { dependency in
                Section {
                    Text(dependency.licenseText)
                        .font(.caption)
                        .monospaced()
                        .listRowBackground(Color.clear)
                } header: {
                    Text(dependency.name)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("More.Attributions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// swiftlint:disable type_body_length
private struct Dependency: Identifiable {
    let id: String
    let name: String
    let licenseText: String

    init(name: String, licenseText: String) {
        self.id = name
        self.name = name
        self.licenseText = licenseText
    }

    static let all: [Dependency] = [
        Dependency(name: "SFBAudioEngine", licenseText:
"""
MIT License

Copyright (c) 2006-2026 Stephen F. Booth

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
""")
    ]
}
// swiftlint:enable type_body_length
