//
//  unitouchApp.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI

@main
struct unitouchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: BackendData.self)
        }
    }
}


extension URL {
  public var queryParameters: [String: String]? {
      guard
          let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
          let queryItems = components.queryItems else { return nil }
      return queryItems.reduce(into: [String: String]()) { (result, item) in
          result[item.name] = item.value
      }
  }
}

extension Color {
    init(rgbInteger: Int) {
        let red = Double((rgbInteger >> 16) & 0xFF) / 255.0
        let green = Double((rgbInteger >> 8) & 0xFF) / 255.0
        let blue = Double(rgbInteger & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
