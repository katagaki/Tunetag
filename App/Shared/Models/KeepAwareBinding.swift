//
//  KeepAwareBinding.swift
//  Tunetag
//

import SwiftUI

/// Binds a text field to an optional value. Text fields write back an empty string when they're focused, which
/// would turn a field that keeps each file's value into one that clears it, so empty writes are ignored while the
/// value is nil. Use the Don't Change button to go back to keeping values.
func keepAwareBinding(_ value: Binding<String?>) -> Binding<String> {
    Binding {
        value.wrappedValue ?? ""
    } set: { newValue in
        guard !(value.wrappedValue == nil && newValue.isEmpty) else { return }
        value.wrappedValue = newValue
    }
}
