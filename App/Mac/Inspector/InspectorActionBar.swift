//
//  InspectorActionBar.swift
//  Tunetag
//

import SwiftUI

struct InspectorActionBar: View {

    let model: TagInspectorModel
    @State private var isTokensPopoverPresented = false
    @State private var isConfirmingRemoveAllTags = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                isTokensPopoverPresented = true
            } label: {
                Image(systemName: "curlybraces")
            }
            .help(MacText.shared("TagEditor.Tokens.Title"))
            .popover(isPresented: $isTokensPopoverPresented, arrowEdge: .top) {
                TokensPopover()
            }
            Menu {
                Button(MacText.shared("TagEditor.RemoveAllTags"), systemImage: "trash", role: .destructive) {
                    isConfirmingRemoveAllTags = true
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuIndicator(.hidden)
            .fixedSize()
            .help(MacText.shared("TagEditor.MoreActions"))
            Spacer()
            if model.isSaving {
                ProgressView(value: Double(model.savedFileCount), total: Double(max(model.files.count, 1)))
                    .frame(width: 80)
            }
            Button(MacText.shared("Shared.Save")) {
                model.save()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canSave)
        }
        .disabled(model.isLoading || model.isSaving)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .confirmationDialog(MacText.shared("TagEditor.RemoveAllTags.Confirm"),
                            isPresented: $isConfirmingRemoveAllTags) {
            Button(MacText.shared("TagEditor.RemoveAllTags"), role: .destructive) {
                model.removeAllTags()
            }
        }
    }
}
