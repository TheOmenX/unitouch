//
//  URL+QueryParameters.swift
//  unitouch
//
//  Created by Tijn Giesberts on 11/03/2026.
//


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