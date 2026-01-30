//
//  ShowManagerController.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 28.01.2026.
//

import SwiftUI

@MainActor
final class ShowManagerController: ObservableObject {
    @Published var isShowing = false

    func open() { isShowing = true }
    func close() { isShowing = false }
}
