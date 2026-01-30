//
//  CSVExportController.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import SwiftUI
import CoreData

@MainActor
final class CSVExportController: ObservableObject {
    @Published var isShowingPreview = false
    @Published var isExporting = false
    @Published var exportDoc = CSVDocument(text: "")
    
    var csvText: String = ""

    func setCSVText(_ text: String) {
        csvText = text
        exportDoc = CSVDocument(text: text)
    }

    func preview() {
        isShowingPreview = true
    }

    @MainActor
    func export() {
        // If Preview is open, close it first
        isShowingPreview = false

        // Present the exporter on the next runloop tick (prevents modal-on-modal)
        DispatchQueue.main.async {
            self.isExporting = true
        }
    }
}
