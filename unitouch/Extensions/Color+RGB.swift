//
//  Color+RGB.swift
//  unitouch
//
//  Created by Tijn Giesberts on 11/03/2026.
//

extension Color {
    init(rgbInteger: Int) {
        let red = Double((rgbInteger >> 16) & 0xFF) / 255.0
        let green = Double((rgbInteger >> 8) & 0xFF) / 255.0
        let blue = Double(rgbInteger & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
