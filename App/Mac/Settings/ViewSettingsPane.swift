//
//  ViewSettingsPane.swift
//  Tunetag
//

import SwiftUI

struct ViewSettingsPane: View {

    private let preferences = ListColumnPreferences.shared

    var body: some View {
        SettingsForm {
            LabeledContent(MacText.string("Settings.ListColumns")) {
                VStack(alignment: .leading, spacing: 8) {
                    List {
                        ForEach(preferences.order) { column in
                            Toggle(isOn: visibilityBinding(for: column)) {
                                Label(column.title, systemImage: column.symbolName)
                            }
                            .disabled(!preferences.isHidden(column) && preferences.visibleColumns.count == 1)
                        }
                        .onMove { source, destination in
                            preferences.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                    .listStyle(.bordered(alternatesRowBackgrounds: true))
                    .frame(width: 320, height: 280)
                    SettingsNote(text: MacText.string("Settings.ListColumns.Note"))
                    Button(MacText.string("Settings.ListColumns.Reset")) {
                        preferences.reset()
                    }
                    .disabled(!preferences.isCustomized)
                }
            }
        }
    }

    private func visibilityBinding(for column: ListColumn) -> Binding<Bool> {
        Binding(
            get: { !preferences.isHidden(column) },
            set: { preferences.setHidden(!$0, for: column) }
        )
    }
}
