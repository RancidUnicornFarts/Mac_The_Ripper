//
//  DiskEditorView.swift
//  Mac_The_Ripper
//

import SwiftUI
import CoreData

struct DiskEditorView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var disk: Disk

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default
    )
    private var shows: FetchedResults<Show>

    @State private var selectedShowID: NSManagedObjectID?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                // NEW: Show assignment
                Picker("Show", selection: $selectedShowID) {
                    Text("Unassigned").tag(Optional<NSManagedObjectID>.none)
                    Divider()
                    ForEach(shows, id: \.objectID) { s in
                        Text(s.name ?? "Untitled Show")
                            .tag(Optional(s.objectID))
                    }
                }

                TextField("File / Folder Name", text: Binding(
                    get: { disk.fileName ?? "" },
                    set: { disk.fileName = $0 }
                ))

                TextField("Default Genre", text: Binding(
                    get: { disk.defaultGenre ?? "" },
                    set: { disk.defaultGenre = $0 }
                ))

                Stepper("Max Titles: \(Int(disk.maxTitles))", value: Binding(
                    get: { Int(disk.maxTitles) },
                    set: { disk.maxTitles = Int16($0) }
                ), in: 1...99)
            }
            .padding()

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    applyShowSelection()
                    do {
                        try ctx.save()
                        dismiss()
                    } catch {
                        ctx.rollback()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 520)
        .onAppear {
            selectedShowID = disk.show?.objectID
        }
    }

    private func applyShowSelection() {
        guard let id = selectedShowID else {
            disk.show = nil
            return
        }
        disk.show = (try? ctx.existingObject(with: id) as? Show)
    }
}
