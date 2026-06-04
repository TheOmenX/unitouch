//
//  Color+Palette.swift
//  unitouch
//
//  Created by Tijn Giesberts on 31/03/2026.
//

import Foundation
import SwiftUI

extension Color {
    // You can pass any standard Color, or a custom HEX/Asset color
    static let primary = ColorPalette(base: Color(red: 0.12, green: 0.84, blue: 0.98))
    //static let background = ColorPalette(base: Color(red: 0.11, green: 0.11, blue: 0.12))
    static let background = ColorPalette(
        base: Color(red: 144/256, green: 149/256, blue: 161/256),
        overrides: [
            200: Color(red: 243/255.0, green: 244/255.0, blue: 246/255.0),
            300: Color(red: 222/255.0, green: 225/255.0, blue: 230/255.0),
            400: Color(red: 189/255.0, green: 193/255.0, blue: 202/255.0),
            600: Color(red: 86/255.0, green: 93/255.0, blue: 109/255.0),
            700: Color(red: 50/255.0, green: 55/255.0, blue: 67/255.0),
            800: Color(red: 30/255.0, green: 33/255.0, blue: 40/255.0),
            900: Color(red: 23/255.0, green: 26/255.0, blue: 31/255.0)
        ]
    )
    
    static let danger = ColorPalette(base: Color(red: 239/256, green: 68/256, blue: 68/256))
}

struct ColorPalette {
    let base: Color
    
    // Store manual overrides in a dictionary
    private let overrides: [Int: Color]
    
    // Initializer allows providing just a base color, or a base color + overrides
    init(base: Color, overrides: [Int: Color] = [:]) {
        self.base = base
        self.overrides = overrides
    }
    
    subscript(weight: Int) -> Color {
        let clamped = max(0, min(1000, weight))
        
        // 1. Check for a manual override first
        if let manualColor = overrides[clamped] {
            return manualColor
        }
        
        // 2. Default to base for 500 if no override exists
        if clamped == 500 {
            return base
        }
        
        // 3. Fallback to HSB calculation
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Extract HSB components
        UIColor(base).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        if clamped < 500 {
            // Lighter tints
            let mixFactor = CGFloat(500 - clamped) / 500.0
            let newBrightness = brightness + (1.0 - brightness) * mixFactor
            let newSaturation = saturation * (1.0 - mixFactor)
            
            return Color(hue: Double(hue), saturation: Double(newSaturation), brightness: Double(newBrightness), opacity: Double(alpha))
            
        } else {
            // Darker shades
            let mixFactor = CGFloat(clamped - 500) / 500.0
            let newBrightness = brightness * (1.0 - pow(mixFactor, 0.8))
            let targetSaturation = min(1.0, saturation * 1.5)
            let newSaturation = saturation + (targetSaturation - saturation) * mixFactor
            
            return Color(hue: Double(hue), saturation: Double(newSaturation), brightness: Double(newBrightness), opacity: Double(alpha))
        }
    }
}
