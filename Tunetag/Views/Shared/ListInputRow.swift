//
//  ListInputRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct ListInputRow: View {

    var title: String
    var placeholder: String?
    @Binding var value: String?
    @State var focusedFieldValue: FocusedField
    var focusedField: FocusState<FocusedField?>.Binding
    @State var isEdited: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(NSLocalizedString(title, comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(
                (value == nil ?
                 String(localized: "BatchEdit.Keep") :
                    NSLocalizedString(title, comment: "")),
                text: Binding(
                get: {
                    return value ?? ""
                },
                set: { newValue in
                    value = newValue
                    isEdited = true
                }
            ))
            .font(.body)
            .focused(focusedField, equals: focusedFieldValue)
            .submitLabel(.next)
            .onSubmit {
                goToNextField()
            }
        }
        .padding([.top, .bottom], 2.0)
    }

    func goToNextField() {
        if let focusedField = focusedField.wrappedValue, focusedField != .discNumber {
            let nextIndex = focusedField.rawValue + 1
            self.focusedField.wrappedValue = FocusedField(rawValue: nextIndex)!
        }
    }
}
