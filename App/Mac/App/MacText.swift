//
//  MacText.swift
//  Tunetag
//

import Foundation

/// Looks up Mac-only strings, which live in their own table so the iOS catalog stays untouched.
enum MacText {

    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), table: "Mac")
    }

    static func shared(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}
