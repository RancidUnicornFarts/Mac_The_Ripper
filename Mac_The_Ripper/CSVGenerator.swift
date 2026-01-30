//
//  CSVGenerator.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import Foundation
import CoreData

enum CSVGenerator {
    // Script-compatible 6 columns, no trailing comma, final newline.
    static func makeScriptCSV(allTitles: [Title]) -> String {
        // Header names to match your Numbers export (cosmetic)
        var lines: [String] = [
            "Foldername,title_number,EP_TITLE,TV_SHOWNAME,YEAR,SEASON"
        ]

        let sorted = allTitles.sorted {
            let aShow = $0.showName ?? ""
            let bShow = $1.showName ?? ""
            if aShow != bShow { return aShow < bShow }

            let aIso = $0.disk?.fileName ?? ""
            let bIso = $1.disk?.fileName ?? ""
            if aIso != bIso { return aIso < bIso }

            return $0.titleNumber < $1.titleNumber
        }

        for t in sorted {
            let folderName = t.disk?.fileName ?? ""
            let titleNumber = String(Int(t.titleNumber))
            let epTitle = t.episodeTitle ?? ""
            let showName = t.showName ?? ""
            let year = t.year ?? ""

            // Build Plex-style season code: SxxEyyy (season width 2 or 3; episode always 3)
            let seasonCode = plexSeasonCode(seasonString: t.seasonNumber, episodeString: t.episodeNumber)

            let fields: [String] = [
                escapeCSV(folderName),
                escapeCSV(titleNumber),
                escapeCSV(epTitle),
                escapeCSV(showName),
                escapeCSV(year),
                escapeCSV(seasonCode)
            ]

            lines.append(fields.joined(separator: ","))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Helpers (place in CSVGenerator)

    private static func plexSeasonCode(seasonString: String?, episodeString: String?) -> String {
        let s = Int((seasonString ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let e = Int((episodeString ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        let seasonWidth = (s >= 100) ? 3 : 2
        let seasonPart = String(format: "%0*d", seasonWidth, s)
        let episodePart = String(format: "%03d", e)

        return "S\(seasonPart)E\(episodePart)"
    }

    private static func escapeCSV(_ value: String) -> String {
        // Minimal CSV escaping: quote if it contains comma, quote, or newline
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

}
