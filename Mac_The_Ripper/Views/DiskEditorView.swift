//  DiskEditorView.swift
//  Mac_The_Ripper
//
//  Core Data entity assumptions (adjust if different):
//    - Disk.title:  String?   (optional)
//    - Disk.tracks: Int16     (non-optional; if optional, see notes below)

import SwiftUI
import CoreData

struct DiskEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var disk: Disk

    @State private var fileNameText: String = ""
    @State private var defaultGenreText: String = ""
    @State private var maxTitlesValue: Int = 0

    var body: some View {
        Form {
            Section("Disk") {
                TextField("File / Folder Name", text: $fileNameText)

                TextField("Default Genre", text: $defaultGenreText)

                Stepper("Max Titles: \(maxTitlesValue)", value: $maxTitlesValue, in: 0...999)
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 240)
        .navigationTitle(fileNameText.isEmpty ? "Edit Disk" : fileNameText)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewContext.rollback()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .onAppear {
            fileNameText = disk.fileName ?? ""
            defaultGenreText = disk.defaultGenre ?? ""
            maxTitlesValue = Int(disk.maxTitles)
        }
    }

    private func save() {
        disk.fileName = fileNameText
        disk.defaultGenre = defaultGenreText
        disk.maxTitles = Int16(clamping: maxTitlesValue)

        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }
            dismiss()
        } catch {
            viewContext.rollback()
        }
    }
}

private extension Int16 {
    init(clamping value: Int) {
        if value < Int(Int16.min) { self = .min }
        else if value > Int(Int16.max) { self = .max }
        else { self = Int16(value) }
    }
}
