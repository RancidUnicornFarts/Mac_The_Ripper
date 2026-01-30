//
//  ShowManagerView.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 28.01.2026.
//

import SwiftUI

struct ShowManagerView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Show.name, ascending: true)])
    private var shows: FetchedResults<Show>

    @State private var name = ""
    @State private var startYear = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("TV Shows")
                .font(.title2)

            GroupBox("Add Show") {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Name") {
                        TextField("", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 420)
                    }
                    LabeledContent("Start Year") {
                        TextField("", text: $startYear)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }

                    HStack {
                        Spacer()
                        Button("Add") { addShow() }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(.vertical, 6)
            }

            GroupBox("Existing") {
                List {
                    ForEach(shows) { s in
                        HStack {
                            Text(s.name ?? "")
                            Spacer()
                            Text(s.startYear ?? "")
                                .foregroundColor(.secondary)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteShow(s)
                            } label: {
                                Text("Delete Show")
                            }
                        }
                    }
                }
                .frame(minHeight: 260)
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(minWidth: 700, minHeight: 580)
    }

    private func addShow() {
        let s = Show(context: context)
        s.id = UUID()
        s.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        s.startYear = startYear.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        name = ""
        startYear = ""
    }

    private func deleteShow(_ show: Show) {
        context.delete(show)
        try? context.save()
    }
}
