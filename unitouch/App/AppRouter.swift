//
//  AppRouter.swift
//  unitouch
//
//  Created by Tijn Giesberts on 18/08/2026.
//


import SwiftUI

enum AppState: Equatable {
    case disconnected
    case login
    case main
    case tableMap
    case splitTableSelection
    case order(tableID: String, subTableIndex: Int)
    case splitOrder
    case payment
}

@MainActor
class AppRouter: ObservableObject {
    @Published var state: AppState = .disconnected
    @Published var preservedState: AppState? = nil
    @Published var activeError: UnitouchError? = nil
    
    @Published var requestMoveConformation: Components.Schemas.RestaurantTable? = nil
    
    // MARK: - Global Overlay State
    @Published var isGlobalLoading: Bool = false
    @Published var loadingMessage: String = ""
    
    // Helper functions
    func showLoading(_ message: String = "Laden...") {
        self.loadingMessage = message
        self.isGlobalLoading = true
    }
    
    func hideLoading() {
        self.isGlobalLoading = false
    }
    
    
    // Global User State
    var currentUser: Components.Schemas.User? {
        didSet {
            // Automatically update the NetworkService when the user logs in/out
            NetworkService.shared.currentUserId = currentUser?.id
        }
    }
    
    func navigate(to newState: AppState) {
        
        self.state = newState
    }
    
    func showError(_ error: UnitouchError) {
        self.activeError = error
    }
}
