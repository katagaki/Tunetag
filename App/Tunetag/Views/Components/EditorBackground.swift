//
//  EditorBackground.swift
//  Tunetag
//

import SwiftUI

/// The grouped background with a soft accent color gradient that fades out from the top.
struct EditorBackground: View {

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            LinearGradient(colors: [Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.14),
                                    Color.accentColor.opacity(colorScheme == .dark ? 0.06 : 0.04),
                                    .clear],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Replaces a list's background with the editor background.
    func editorListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(EditorBackground())
    }

    /// Gives list rows a material background so they sit on the gradient like frosted cards.
    func editorRowBackground() -> some View {
        listRowBackground(Rectangle().fill(.regularMaterial))
    }
}
