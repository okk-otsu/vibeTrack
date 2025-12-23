//
//  ColorHex.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI

extension Color {

    /// Создание Color из hex строки (#RRGGBB или RRGGBB)
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }

    /// Конвертация Color → hex (#RRGGBB)
    func toHex() -> String {
        #if os(iOS)
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components else {
            return "#000000"
        }

        let r = Int((components.count > 0 ? components[0] : 0) * 255)
        let g = Int((components.count > 1 ? components[1] : 0) * 255)
        let b = Int((components.count > 2 ? components[2] : 0) * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.deviceRGB) else {
            return "#000000"
        }

        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
        #endif
    }
}
