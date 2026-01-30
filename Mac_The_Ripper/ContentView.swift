import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Disk.fileName, ascending: true)],
        animation: .default
    )
    private var disks: FetchedResults<Disk>

    @State private var selection: NSManagedObjectID?
    @State private var editingID: NSManagedObjectID?

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                ForEach(disks, id: \.objectID) { disk in
                    DiskRow(disk: disk)
                        .tag(disk.objectID)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Edit…") { editingID = disk.objectID }
                            Divider()
                            Button("Delete", role: .destructive) { delete(disk) }
                        }
                        .simultaneousGesture(
                            TapGesture(count: 2).onEnded {
                                editingID = disk.objectID
                            }
                        )
                }
            }
            .navigationTitle("Disks")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        addDisk()
                    } label: {
                        Label("Add Disk", systemImage: "plus")
                    }

                    Button {
                        deleteSelection()
                    } label: {
                        Label("Delete Disk", systemImage: "trash")
                    }
                    .disabled(selection == nil)
                }
            }
            .onDeleteCommand { deleteSelection() }
            .sheet(item: $editingID.asBox) { box in
                if let disk = try? viewContext.existingObject(with: box.id) as? Disk {
                    DiskEditorView(disk: disk)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }

    // MARK: - Actions

    private func addDisk() {
        let disk = Disk(context: viewContext)
        disk.id = UUID()
        disk.fileName = "Untitled"
        disk.defaultGenre = ""
        disk.maxTitles = 0

        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            return
        }

        selection = disk.objectID
        editingID = disk.objectID
    }

    private func deleteSelection() {
        guard let id = selection,
              let disk = try? viewContext.existingObject(with: id) as? Disk
        else { return }
        delete(disk)
    }

    private func delete(_ disk: Disk) {
        guard let ctx = disk.managedObjectContext else { return }

        ctx.delete(disk)

        do {
            try ctx.save()
        } catch {
            ctx.rollback()
            return
        }

        if selection == disk.objectID {
            selection = nil
        }
    }
}

// MARK: - Row

private struct DiskRow: View {
    @ObservedObject var disk: Disk

    var body: some View {
        HStack {
            Text(disk.fileName ?? "Untitled")
                .lineLimit(1)

            Spacer()

            // Show maxTitles on the right (replaces old "tracks")
            Text("\(Int(disk.maxTitles))")
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Helpers

private struct ObjectIDBox: Identifiable {
    let id: NSManagedObjectID
}

private extension Optional where Wrapped == NSManagedObjectID {
    var asBox: ObjectIDBox? {
        get { self.map(ObjectIDBox.init(id:)) }
        set { self = newValue?.id }
    }
}
