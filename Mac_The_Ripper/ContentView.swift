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

    var selectedDisk: Disk? {
        guard let id = selection else { return nil }
        return try? viewContext.existingObject(with: id) as? Disk
    }
    
    var body: some View {
        NavigationSplitView {
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
                            TapGesture(count: 2).onEnded { editingID = disk.objectID }
                        )
                }
            }
            .navigationTitle("Disks")
            .toolbar {
                Button { addDisk() } label: { Image(systemName: "plus") }
                Button { deleteSelection() } label: { Image(systemName: "trash") }
                    .disabled(selection == nil)
            }
            .onDeleteCommand { deleteSelection() }

        } detail: {
            if let disk = selectedDisk {
                TitlesListView(disk: disk)
            } else {
                Text("Select a disk")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(item: $editingID.asBox) { box in
            if let disk = try? viewContext.existingObject(with: box.id) as? Disk {
                DiskEditorView(disk: disk)
            }
        }
    }

    // MARK: - Actions

    @State private var lastError: String?
    @State private var showingError = false

    private func addDisk() {
        let disk = Disk(context: viewContext)
        disk.id = UUID()
        disk.fileName = "Untitled"
        disk.defaultGenre = ""
        disk.maxTitles = 12

        do {
            try viewContext.save()
            selection = disk.objectID
            editingID = disk.objectID        // if you show a sheet editor
        } catch {
            viewContext.rollback()
            lastError = error.localizedDescription
            showingError = true
        }
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

struct TitlesListView: View {
    @Environment(\.managedObjectContext) private var ctx
    let disk: Disk

    @FetchRequest private var titles: FetchedResults<Title>

    init(disk: Disk) {
        self.disk = disk
        _titles = FetchRequest(
            sortDescriptors: [NSSortDescriptor(key: "titleNumber", ascending: true)],
            predicate: NSPredicate(format: "disk == %@", disk),
            animation: .default
        )
    }

    var body: some View {
        List {
            ForEach(titles, id: \.objectID) { t in
                HStack {
                    Text("\(Int(t.titleNumber))").monospacedDigit()
                    Text(t.episodeTitle ?? "")
                    Spacer()
                    Text(t.showName ?? "")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(disk.fileName ?? "Disk")
    }
}
