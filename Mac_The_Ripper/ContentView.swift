//
//  ContentView.swift
//  Mac_The_Ripper
//

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
    @State private var editingDiskID: NSManagedObjectID?

    @State private var lastError: String?
    @State private var showingError = false

    private var selectedDisk: Disk? {
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
                        .simultaneousGesture(
                            TapGesture(count: 1).onEnded {
                                selection = disk.objectID
                            }
                        )
                        .simultaneousGesture(
                            TapGesture(count: 2).onEnded {
                                selection = disk.objectID
                                editingDiskID = disk.objectID
                            }
                        )
                        .contextMenu {
                            Button("Edit…") { editingDiskID = disk.objectID }
                            Divider()
                            Button("Delete", role: .destructive) { deleteDisk(disk) }
                        }
                }

            }
            .listStyle(.sidebar)
            .navigationTitle("Disks")
            .toolbar {
                ToolbarItemGroup {
                    Button { addDisk() } label: { Image(systemName: "plus") }
                    Button { deleteSelection() } label: { Image(systemName: "trash") }
                        .disabled(selection == nil)
                }
            }
            .onDeleteCommand { deleteSelection() }
        } detail: {
            NavigationStack {
                if let disk = selectedDisk {
                    TitlesListView(disk: disk)
                } else {
                    Text("Select a disk")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }

        .sheet(item: $editingDiskID.asBox) { box in
            if let disk = try? viewContext.existingObject(with: box.id) as? Disk {
                DiskEditorView(disk: disk)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .alert("Error", isPresented: $showingError, presenting: lastError) { _ in
            Button("OK", role: .cancel) {}
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Disk actions

    private func addDisk() {
        let disk = Disk(context: viewContext)
        disk.id = UUID()
        disk.fileName = "Untitled"
        disk.defaultGenre = ""
        disk.maxTitles = 12

        do {
            try viewContext.save()
            selection = disk.objectID
            editingDiskID = disk.objectID
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
        deleteDisk(disk)
    }

    private func deleteDisk(_ disk: Disk) {
        guard let ctx = disk.managedObjectContext else { return }
        ctx.delete(disk)
        do {
            try ctx.save()
            if selection == disk.objectID { selection = nil }
        } catch {
            ctx.rollback()
            lastError = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Disk row

private struct DiskRow: View {
    @ObservedObject var disk: Disk

    var body: some View {
        HStack {
            Text(disk.fileName ?? "Untitled")
                .lineLimit(1)
            Spacer()
            Text("\(Int(disk.maxTitles))")
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Titles list (detail)

private struct TitlesListView: View {
    @Environment(\.managedObjectContext) private var ctx
    let disk: Disk

    @State private var titleSelection: NSManagedObjectID?
    @State private var editRequest: TitleEditRequest?

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
        List(selection: $titleSelection) {
            ForEach(titles, id: \.objectID) { t in
                TitleRow(title: t)
                    .tag(t.objectID)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Edit…") { editRequest = .edit(t.objectID) }
                        Divider()
                        Button("Delete", role: .destructive) { deleteTitle(t) }
                    }
                    .simultaneousGesture(
                        TapGesture(count: 2).onEnded { editRequest = .edit(t.objectID) }
                    )
            }
        }
        .navigationTitle(disk.fileName ?? "Disk")
        .toolbar {
            ToolbarItemGroup {
                Button { editRequest = .new } label: { Image(systemName: "plus") }
                Button { deleteSelectedTitle() } label: { Image(systemName: "trash") }
                    .disabled(titleSelection == nil)
            }
        }
        .onDeleteCommand { deleteSelectedTitle() }
        .sheet(item: $editRequest) { req in
            if let diskInCtx = try? ctx.existingObject(with: disk.objectID) as? Disk {
                let titleToEdit: Title? = {
                    guard let tid = req.titleID else { return nil }
                    return try? ctx.existingObject(with: tid) as? Title
                }()

                TitleEditorView(disk: diskInCtx, titleToEdit: titleToEdit)
                    .environment(\.managedObjectContext, ctx)
            } else {
                Text("Internal error: disk not found.")
                    .padding()
                    .frame(minWidth: 360, minHeight: 200)
            }
        }
    }

    private func deleteSelectedTitle() {
        guard let id = titleSelection,
              let t = try? ctx.existingObject(with: id) as? Title
        else { return }
        deleteTitle(t)
    }

    private func deleteTitle(_ t: Title) {
        ctx.delete(t)
        do {
            try ctx.save()
            if titleSelection == t.objectID { titleSelection = nil }
        } catch {
            ctx.rollback()
        }
    }
}

// MARK: - Title row

private struct TitleRow: View {
    @ObservedObject var title: Title

    var body: some View {
        HStack(spacing: 12) {
            Text("\(Int(title.titleNumber))")
                .monospacedDigit()
                .frame(width: 36, alignment: .leading)

            Text(title.episodeTitle ?? "")
                .lineLimit(1)

            Spacer()

            Text(title.showName ?? "")
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sheet request type

private struct TitleEditRequest: Identifiable {
    let id = UUID()
    let titleID: NSManagedObjectID?

    static var new: TitleEditRequest { .init(titleID: nil) }
    static func edit(_ id: NSManagedObjectID) -> TitleEditRequest { .init(titleID: id) }
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
