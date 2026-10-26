//
//  TagEditorSheet.swift
//  Tunetag
//

import SwiftUI

struct TagEditorSheet: View {

    @Environment(\.dismiss) var dismiss
    var files: [FSFile]
    var accessedURLs: [URL] = []
    @State var showsTokens: Bool = false

    var body: some View {
        NavigationStack {
            TagEditorView(files: files)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("TagEditor.Tokens.Title", systemImage: "questionmark") {
                            showsTokens = true
                        }
                        .popoverTip(AvailableTokensTip(), arrowEdge: .top)
                        .popover(isPresented: $showsTokens) {
                            AvailableTokensPopover()
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if #available(iOS 26.0, *) {
                            Button(role: .close) {
                                dismiss()
                            }
                        } else {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.footnote.weight(.bold))
                                    .padding(7)
                                    .background(Color(.systemFill), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
        }
        .onDisappear {
            files.forEach { URL(filePath: $0.path).stopAccessingSecurityScopedResource() }
            accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        }
    }
}
