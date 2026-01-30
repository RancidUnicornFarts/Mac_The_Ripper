//
//  CSVPreviewView.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct CSVPreviewView: View {
    let disk: Disk
    @State private var filter = "TV Show" // "TV Show" or "Movie"
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("Filter", selection: $filter) {
                Text("TV Show").tag("TV Show")
                Text("Movie").tag("Movie")
            }
            .pickerStyle(.segmented)
            
            ScrollView {
                Text(csvText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .border(Color.gray.opacity(0.4))
            
            HStack {
                Spacer()
                Button("Export CSV…") {
                    Task { @MainActor in
                        exportCSV()
                    }
                }
                .keyboardShortcut(.defaultAction)
                
            }
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 520)
    }
    
    private var csvText: String {
        makeScriptCSV(for: disk.titlesArray, mediaType: filter)
    }
    
    // Script-compatible (6 columns), no quoting/escaping
    private func makeScriptCSV(for titles: [Title], mediaType: String) -> String {
        var lines: [String] = [
            "ISOFILE,title_number,EP_TITLE,TV_SHOWNAME,YEAR,SEASON"
        ]
        
        let filtered = titles
            .filter { ($0.mediaType ?? "") == mediaType }
            .sorted { $0.titleNumber < $1.titleNumber }
        
        let isoFile = disk.fileName ?? ""
        
        for t in filtered {
            let fields: [String] = [
                isoFile,
                String(Int(t.titleNumber)),
                t.episodeTitle ?? "",
                t.showName ?? "",
                t.year ?? "",
                t.seasonNumber ?? ""
            ]
            lines.append(fields.joined(separator: ","))
        }
        
        return lines.joined(separator: "\n") + "\n"
    }
    
    @MainActor
    private func exportCSV() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "input.csv"
        
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [UTType.commaSeparatedText]
        } else {
            panel.allowedFileTypes = ["csv"]
        }
        
        // IMPORTANT: run modal (safe even when you're already in a sheet)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
