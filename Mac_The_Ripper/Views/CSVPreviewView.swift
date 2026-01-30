//
//  CSVPreviewView.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import SwiftUI

struct CSVPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("CSV Preview").font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }

            TextEditor(text: .constant(text))
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 900, minHeight: 600)
        }
        .padding(16)
    }
}
