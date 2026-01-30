//
//  ShowComboBox.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 28.01.2026.
//

import SwiftUI
import AppKit

struct ShowComboBox: NSViewRepresentable {
    @Binding var text: String
    var items: [String]

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSComboBox {
        let cb = NSComboBox()
        cb.usesDataSource = false
        cb.completes = true
        cb.isEditable = true
        cb.delegate = context.coordinator
        cb.addItems(withObjectValues: items)
        cb.stringValue = text
        return cb
    }

    func updateNSView(_ nsView: NSComboBox, context: Context) {
        // Refresh items if needed
        nsView.removeAllItems()
        nsView.addItems(withObjectValues: items)

        // Keep UI in sync with binding
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSComboBoxDelegate, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            text = tf.stringValue
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let cb = notification.object as? NSComboBox else { return }
            text = cb.stringValue
        }
    }
}
