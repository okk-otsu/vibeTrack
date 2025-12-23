//
//  ColorPickerGrid.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI

struct ColorPickerGrid: View {
    let palette: [String]
    @Binding var selectedHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 10)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(palette, id: \.self) { hex in
                let isSelected = (hex == selectedHex)

                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : .clear, lineWidth: 2)
                    )
                    .contentShape(Circle())
                    .onTapGesture { selectedHex = hex }
            }
        }
        .padding(.vertical, 6)
    }
}
