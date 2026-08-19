//
//  unitouchApp.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI

@main
struct unitouchApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var store = RestaurantStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Payment.self)
                .environment(\.font, .custom("Roboto-Regular", size: 16))
                .environmentObject(router)
                .environmentObject(store)
        }
    }
}
