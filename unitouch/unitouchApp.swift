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
