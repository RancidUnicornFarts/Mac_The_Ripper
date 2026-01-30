//
//  TrackGridView.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import SwiftUI

struct TrackGridView: View {
    let max: Int
    let occupied: Set<Int>
    let current: Int

    private let cols = Array(repeating: GridItem(.fixed(30)), count: 8)

    var body: some View {
        LazyVGrid(columns: cols, spacing: 6) {
            ForEach(1...max, id: \.self) { n in
                Text("\(n)")
                    .font(.caption)
                    .frame(width: 28, height: 28)
                    .background(
                        n == current ? .blue :
                        occupied.contains(n) ? .gray :
                        Color.gray.opacity(0.2)
                    )
                    .foregroundColor(occupied.contains(n) ? .white : .primary)
                    .cornerRadius(4)
            }
        }
    }
}
