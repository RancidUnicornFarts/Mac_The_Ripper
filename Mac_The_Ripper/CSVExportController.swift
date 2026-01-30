//
//  CSVExportController.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import SwiftUI
import AppKit

@MainActor
final class CSVExportController: ObservableObject {
    @Published var isShowingPreview: Bool = false
    @Published var csvText: String = ""

    // Optional convenience (useful from App commands)
    func setCSVText(_ text: String) {
        csvText = text
    }

    func showPreview() {
        isShowingPreview = true
    }

    func hidePreview() {
        isShowingPreview = false
    }

    /// Shows a "Save As…" dialog and writes `csvText` as UTF-8 to the chosen location.
    /// Default filename: input.csv
    func export() {
        let panel = NSSavePanel()
        panel.title = "Export CSV"
        panel.nameFieldStringValue = "input.csv"
        panel.canCreateDirectories = true

        // Prefer modern type filtering; fall back for older SDKs.
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.commaSeparatedText]
        } else {
            panel.allowedFileTypes = ["csv"]
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
