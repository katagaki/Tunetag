//
//  ListDetailRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct ListDetailRow: View {

    var title: String
    var placeholder: String?
    @Binding var value: String
    @State var focusedFieldValue: FocusedField
    var focusedField: FocusState<FocusedField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(NSLocalizedString(title, comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            Group {
                if let placeholder = placeholder {
                    TextField(NSLocalizedString(placeholder, comment: ""),
                              text: $value)
                    .font(.body)
                } else {
                    TextField(NSLocalizedString(title, comment: ""),
                              text: $value)
                    .font(.body)
                }
            }
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
