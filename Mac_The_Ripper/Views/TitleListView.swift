//
//  TitleListView.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import SwiftUI
import CoreData

struct TitleListView: View {
    @ObservedObject var disk: Disk

    @FetchRequest private var titles: FetchedResults<Title>

    @State private var showAddEditor = false
    @State private var editingTitle: Title? = nil

    init(disk: Disk) {
        self.disk = disk
        _titles = FetchRequest<Title>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Title.titleNumber, ascending: true)],
            predicate: NSPredicate(format: "disk == %@", disk),
            animation: .default
        )
    }

    var body: some View {
        VStack {
            List {
                ForEach(titles) { title in
                    HStack(spacing: 12) {
                        Text(String(format: "%02d", Int(title.titleNumber)))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 36, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title.episodeTitle ?? "")
                                .font(.headline)

                            Text("\(title.showName ?? "") • S\(title.seasonNumber ?? "")E\(title.episodeNumber ?? "") • \(title.year ?? "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if title.isVAM {
                            Text("VAM")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingTitle = title
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteTitle(title)
                        } label: {
                            Text("Delete Track")
                        }
                    }
                }
                .onDelete(perform: deleteOffsets)
            }

            HStack {
                Button("Add Title") { showAddEditor = true }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $showAddEditor) {
            TitleEditorView(disk: disk, titleToEdit: nil)
        }
        .sheet(item: $editingTitle) { title in
            TitleEditorView(disk: disk, titleToEdit: title)
        }
    }

    private func deleteOffsets(at offsets: IndexSet) {
        offsets.map { titles[$0] }.forEach(deleteTitle)
    }

    private func deleteTitle(_ title: Title) {
        let ctx = title.managedObjectContext ?? disk.managedObjectContext
        ctx?.delete(title)
        try? ctx?.save()
    }
}
