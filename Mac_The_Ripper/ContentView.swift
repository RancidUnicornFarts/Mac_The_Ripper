//
//  ContentView.swift
//  Mac_The_Ripper
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Column 1: Shows
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.name, ascending: true)],
        predicate: nil,
        animation: .default
    )
    private var shows: FetchedResults<Show>

    // Selections
    @State private var showFilter: ShowFilter = .unassigned
    @State private var diskSelection: NSManagedObjectID?
    @State private var editingDiskID: NSManagedObjectID?

    // Error UI
    @State private var lastError: String?
    @State private var showingError = false

    private var selectedDisk: Disk? {
        guard let id = diskSelection else { return nil }
        return try? viewContext.existingObject(with: id) as? Disk
    }

    var body: some View {
        NavigationSplitView {
            // MARK: - Column 1: Shows
            List(selection: $showFilter) {
                Text("Unassigned")
                    .tag(ShowFilter.unassigned)

                Section("Shows") {
                    ForEach(shows, id: \.objectID) { s in
                        Text(s.name ?? "Untitled Show")
                            .lineLimit(1)
                            .tag(ShowFilter.show(s.objectID))
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Shows")
            .onChange(of: showFilter) { _, _ in
                // Reset disk selection when switching shows
                diskSelection = nil
            }

        } content: {
            // MARK: - Column 2: Disks
            DisksColumn(
                showFilter: $showFilter,
                diskSelection: $diskSelection,
                editingDiskID: $editingDiskID,
                onError: presentError(_:),
                onAddDisk: addDisk(manuallyFor:)
            )
            .environment(\.managedObjectContext, viewContext)

        } detail: {
            // MARK: - Column 3: Titles
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

    // MARK: - Disk create helper

    private func addDisk(manuallyFor show: Show?) {
        let disk = Disk(context: viewContext)
        disk.id = UUID()
        disk.fileName = "Untitled"
        disk.defaultGenre = ""
        disk.maxTitles = 12
        disk.show = show

        do {
            try viewContext.save()
            diskSelection = disk.objectID
            editingDiskID = disk.objectID
        } catch {
            viewContext.rollback()
            presentError(error.localizedDescription)
        }
    }

    private func presentError(_ msg: String) {
        lastError = msg
        showingError = true
    }
}

// MARK: - Column 2: Disks

private struct DisksColumn: View {
    @Environment(\.managedObjectContext) private var ctx

    @Binding var showFilter: ShowFilter
    @Binding var diskSelection: NSManagedObjectID?
    @Binding var editingDiskID: NSManagedObjectID?

    let onError: (String) -> Void
    let onAddDisk: (Show?) -> Void

    @State private var isDropTarget = false

    var body: some View {
        // Key trick: force this subtree to be rebuilt when showFilter changes,
        // so the FetchRequest is re-initialized with the right predicate.
        DisksList(
            showFilter: showFilter,
            diskSelection: $diskSelection,
            editingDiskID: $editingDiskID,
            onError: onError,
            onAddDisk: onAddDisk
        )
        .id(showFilter) // rebuild on filter change
    }
}

private struct DisksList: View {
    @Environment(\.managedObjectContext) private var ctx

    let showFilter: ShowFilter
    @Binding var diskSelection: NSManagedObjectID?
    @Binding var editingDiskID: NSManagedObjectID?

    let onError: (String) -> Void
    let onAddDisk: (Show?) -> Void

    @State private var isDropTarget = false

    @FetchRequest private var disks: FetchedResults<Disk>

    init(
        showFilter: ShowFilter,
        diskSelection: Binding<NSManagedObjectID?>,
        editingDiskID: Binding<NSManagedObjectID?>,
        onError: @escaping (String) -> Void,
        onAddDisk: @escaping (Show?) -> Void
    ) {
        self.showFilter = showFilter
        _diskSelection = diskSelection
        _editingDiskID = editingDiskID
        self.onError = onError
        self.onAddDisk = onAddDisk

        let predicate: NSPredicate
        switch showFilter {
        case .unassigned:
            predicate = NSPredicate(format: "show == nil")
        case .show:
            // Can't resolve Show in init (no @Environment ctx yet). Fetch all assigned, filter in-memory.
            predicate = NSPredicate(format: "show != nil")
        }


        _disks = FetchRequest(
            sortDescriptors: [NSSortDescriptor(key: "fileName", ascending: true)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        List(selection: $diskSelection) {
            ForEach(filteredDisks, id: \.objectID) { disk in
                DiskRow(disk: disk)
                    .tag(disk.objectID)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2).onEnded {
                            diskSelection = disk.objectID
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
        .navigationTitle(disksTitle)
        .toolbar {
            ToolbarItemGroup {
                Button { onAddDisk(selectedShow) } label: { Image(systemName: "plus") }
                Button { deleteSelectedDisk() } label: { Image(systemName: "trash") }
                    .disabled(diskSelection == nil)
            }
        }
        .onDeleteCommand { deleteSelectedDisk() }
        .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
            handleDiskDrop(providers: providers)
        }
    }

    private var disksTitle: String {
        switch showFilter {
        case .unassigned: return "Disks (Unassigned)"
        case .show: return "Disks"
        }
    }

    private var selectedShow: Show? {
        guard case .show(let id) = showFilter else { return nil }
        return try? ctx.existingObject(with: id) as? Show
    }

    private func deleteSelectedDisk() {
        guard let id = diskSelection,
              let disk = try? ctx.existingObject(with: id) as? Disk
        else { return }
        deleteDisk(disk)
    }

    private func deleteDisk(_ disk: Disk) {
        ctx.delete(disk)
        do {
            try ctx.save()
            if diskSelection == disk.objectID { diskSelection = nil }
        } catch {
            ctx.rollback()
            onError(error.localizedDescription)
        }
    }
    
    private var filteredDisks: [Disk] {
        switch showFilter {
        case .unassigned:
            return Array(disks) // already filtered by predicate
        case .show(let showID):
            return disks.filter { $0.show?.objectID == showID }
        }
    }


    private func handleDiskDrop(providers: [NSItemProvider]) -> Bool {
        for p in providers where p.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL? = {
                    if let u = item as? URL { return u }
                    if let data = item as? Data { return URL(dataRepresentation: data, relativeTo: nil) }
                    return nil
                }()
                guard let url else { return }

                Task { @MainActor in
                    let disk = Disk(context: ctx)
                    disk.id = UUID()
                    disk.fileName = url.lastPathComponent
                    disk.defaultGenre = ""
                    disk.maxTitles = 12
                    disk.show = selectedShow

                    do {
                        try ctx.save()
                        diskSelection = disk.objectID
                        editingDiskID = disk.objectID
                    } catch {
                        ctx.rollback()
                        onError(error.localizedDescription)
                    }
                }
            }
            return true
        }
        return false
    }
}


// MARK: - Show filter type for column 1

private enum ShowFilter: Hashable {
    case unassigned
    case show(NSManagedObjectID)
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
