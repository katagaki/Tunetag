//
//  ProgressAlert.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/10.
//

import SwiftUI

struct ProgressAlert: View {

    @State var title: String
    @State var message: String
    @Binding var percentage: Int
    @State var onCancel: () -> ()

    var body: some View {
        ZStack(alignment: .center) {
            Color.black.opacity(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(alignment: .center, spacing: 0.0) {
                VStack(alignment: .center, spacing: 10.0) {
                    Text(NSLocalizedString(title, comment: ""))
                        .bold()
                    ProgressView(value: Float(percentage), total: 100.0)
                        .progressViewStyle(.linear)
                    Text(NSLocalizedString(message, comment: "")
                        .replacingOccurrences(of: "%1", with: String(percentage)))
                    .font(.subheadline)
                }
                .padding()
                Divider()
                Button {
                    onCancel()
                } label: {
                    Text("Shared.Cancel")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
                .padding([.top, .bottom], 12.0)
            }
            .background(.thickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
            .padding(.all, 32.0)
        }
        .transition(AnyTransition.opacity)
    }
}
