//
//  Title+Plex.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 10.02.2026.
//

import Foundation
import CoreData

private extension NSManagedObject {
    func hasAttribute(_ name: String) -> Bool {
        entity.attributesByName[name] != nil
    }

    func stringValueIfExists(_ name: String) -> String? {
        guard hasAttribute(name) else { return nil }

        let v = value(forKey: name)
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return nil
    }

    func boolValueIfExists(_ name: String) -> Bool? {
        guard hasAttribute(name) else { return nil }

        let v = value(forKey: name)
        if let b = v as? Bool { return b }
        if let n = v as? NSNumber { return n.boolValue }
        return nil
    }
}

// Title+Plex.swift

extension Title {

    var seasonRaw: String? {
        stringValueIfExists("seasonNumber")   // <- matches model
        ?? stringValueIfExists("season")
        ?? stringValueIfExists("seasonNo")
    }

    var episodeRaw: String? {
        stringValueIfExists("episodeNumber")  // <- matches model
        ?? stringValueIfExists("episode")
        ?? stringValueIfExists("episodeNo")
    }

    var isVAMFlag: Bool {
        boolValueIfExists("isVAM")            // <- matches model
        ?? boolValueIfExists("vam")
        ?? boolValueIfExists("valueAddedMaterial")
        ?? false
    }

    var plexShowNumber: String? {
        guard let season = seasonRaw?.digitsOnly, !season.isEmpty else { return nil }

        let s2 = season.leftPadded(to: 2, with: "0")

        let epDigits = (episodeRaw?.digitsOnly ?? "")
        let eRaw = isVAMFlag ? "0" : epDigits
        let e3 = (eRaw.isEmpty ? "0" : eRaw).leftPadded(to: 3, with: "0")

        return "S\(s2)E\(e3)"
    }
}
