//
//  TagInspectorView.swift
//  Tunetag
//

import SwiftUI

struct TagInspectorView: View {

    @Bindable var model: TagInspectorModel

    var body: some View {
        Group {
            if model.files.isEmpty {
                ContentUnavailableView {
                    Label(MacText.string("Inspector.NoSelection"), systemImage: "music.note")
                } description: {
                    Text(MacText.string("Inspector.NoSelection.Description"))
                }
            } else if model.loadedFiles.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TagInspectorForm(model: model)
            }
        }
        .alert(MacText.shared("TagEditor.SaveFailed.Message"), isPresented: $model.isShowingSaveError) {
            Button(MacText.shared("Shared.OK"), role: .cancel) { }
        }
        .alert(MacText.shared("TagEditor.RemoveAllTags.Failed"), isPresented: $model.isShowingRemoveTagsError) {
            Button(MacText.shared("Shared.OK"), role: .cancel) { }
        }
    }
}
