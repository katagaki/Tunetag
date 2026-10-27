//
//  AttributionsSettingsPane.swift
//  Tunetag
//

import SwiftUI

/// The dependencies listed on the left and the selected one's license on the
/// right, with the source code link in the bottom-right corner.
struct AttributionsSettingsPane: View {

    private static let sourceCodeURL = URL(string: "https://github.com/katagaki/Tunetag")!

    @Environment(\.openURL) private var openURL
    private let dependencies = Dependency.loadAll()
    @State private var selection: Dependency?

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                List(dependencies, selection: $selection) { dependency in
                    Text(dependency.displayName)
                        .tag(dependency)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(.fill.quinary, in: .rect(cornerRadius: 10))
                .frame(width: 200)
                ScrollView {
                    Text(selection?.licenseText ?? "")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(.fill.quinary, in: .rect(cornerRadius: 10))
            }
            Button {
                openURL(Self.sourceCodeURL)
            } label: {
                Label(MacText.shared("More.GitHub"), systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
        .padding(20)
        .frame(width: 680, height: 440)
        .onAppear {
            if selection == nil {
                selection = dependencies.first
            }
        }
    }
}
