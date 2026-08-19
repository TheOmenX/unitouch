//
//  Color+RGB.swift
//  unitouch
//
//  Created by Tijn Giesberts on 11/03/2026.
//

import SwiftUI

extension Color {
    init(rgbInteger: Int) {
        let red = Double((rgbInteger >> 16) & 0xFF) / 255.0
        let green = Double((rgbInteger >> 8) & 0xFF) / 255.0
        let blue = Double(rgbInteger & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

extension Color {
    init(hex: String) {
        let hexFormatted = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hexFormatted.count {
        case 6: // RGB (e.g. #FF0000 or FF0000)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB / RGBA with opacity
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
