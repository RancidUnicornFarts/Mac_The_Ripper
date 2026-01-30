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
        var lines: [String] = [
            "ISOFILE,title_number,EP_TITLE,TV_SHOWNAME,YEAR,SEASON"
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
            let isoFile = t.disk?.fileName ?? ""
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
}
