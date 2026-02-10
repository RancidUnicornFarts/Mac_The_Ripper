//
//  CSVGenerator.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import Foundation
import CoreData

enum CSVGenerator {
    
    // File: CSVGenerator.swift

    private static func parseInt(_ s: String?) -> Int? {
        guard let s, !s.isEmpty else { return nil }
        return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func plexSeasonEpisode(season: String?, episode: String?) -> String {
        // Season: 2 digits (or 3 if you ever exceed 99; format handles 100+ naturally)
        // Episode: 3 digits (Plex-friendly)
        let s = parseInt(season) ?? 0
        let e = parseInt(episode) ?? 0
        return String(format: "S%02dE%03d", s, e)
    }

    
    
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

        // File: CSVGenerator.swift

        for t in sorted {
            let isoFile = t.disk?.fileName ?? ""

            let seasonField = plexSeasonEpisode(
                season: t.seasonNumber,
                episode: t.episodeNumber
            )

            let fields: [String] = [
                isoFile,
                String(Int(t.titleNumber)),
                t.episodeTitle ?? "",
                t.showName ?? "",
                t.year ?? "",
                seasonField
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
