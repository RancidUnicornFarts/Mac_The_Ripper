//
//  Mac_The_RipperApp.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import SwiftUI
import AppKit
import CoreData

@main
struct Mac_The_RipperApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var csvController = CSVExportController()
    @StateObject private var showManager = ShowManagerController()
    @State private var showingTVShows = false

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .sheet(isPresented: $csvController.isShowingPreview) {
                    CSVPreviewView(text: csvController.csvText)
                }
        }

        .commands {
            CommandGroup(after: .newItem) {

                Button("Manage TV Shows…") {
                    showManager.open()
                }
                .keyboardShortcut("T", modifiers: [.command, .shift])

                Divider()

                Button("Preview CSV…") {
                    previewCSV()
                }
                .keyboardShortcut("P", modifiers: [.command, .shift])

                Button("Export CSV…") {
                    exportCSV()
                }
                .keyboardShortcut("E", modifiers: [.command, .shift])

            }
        }


    }

    private func previewCSV() {
        let titles = fetchAllTitles()
        let csv = CSVGenerator.makeScriptCSV(allTitles: titles)
        csvController.csvText = csv
        csvController.isShowingPreview = true
    }

    private func exportCSV() {
        let titles = fetchAllTitles()
        let csv = CSVGenerator.makeScriptCSV(allTitles: titles)
        csvController.csvText = csv
        csvController.export()
    }

    private func fetchAllTitles() -> [Title] {
        let ctx = persistenceController.container.viewContext
        let req = NSFetchRequest<Title>(entityName: "Title")
        req.sortDescriptors = [
            NSSortDescriptor(key: "showName", ascending: true),
            NSSortDescriptor(key: "titleNumber", ascending: true)
        ]
        return (try? ctx.fetch(req)) ?? []
    }

}
