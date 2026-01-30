//
//  Disk+Extensions.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import CoreData

extension Disk {
    var titlesArray: [Title] {
        let set = titles as? Set<Title> ?? []
        return set.sorted { $0.titleNumber < $1.titleNumber }
    }
}
