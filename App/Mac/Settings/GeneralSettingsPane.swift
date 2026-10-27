//
//  GeneralSettingsPane.swift
//  Tunetag
//

import SwiftUI

struct GeneralSettingsPane: View {

    @AppStorage(Preferences.startWithPreviousSelectionKey) private var startsWithPreviousSelection = false

    var body: some View {
        SettingsForm {
            LabeledContent(MacText.string("Settings.OnLaunch")) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(MacText.string("Settings.StartWithPreviousSelection"), isOn: $startsWithPreviousSelection)
                    SettingsNote(text: MacText.string("Settings.StartWithPreviousSelection.Note"))
                }
            }
        }
    }
}
