//
//  String+Helpers.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 10.02.2026.
//

// String+Helpers.swift

import Foundation

// String+Helpers.swift

extension String {
    var digitsOnly: String { filter(\.isNumber) }

    func leftPadded(to length: Int, with pad: Character) -> String {
        if count >= length { return self }
        return String(repeating: String(pad), count: length - count) + self
    }
}
