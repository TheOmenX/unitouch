//
//  SessionManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 26/01/2026.
//

import Foundation
import Combine

// --- APP STATE ENUM ---
enum AppState: Equatable {
    case disconnected
    case loading(String)
    case userSelection                      // Screen 1: Pick User
    case pinEntry                             // Screen 2: Enter PIN
    case main                            // Screen 3: Main Input
    case order(TableInfo)                                   // Screen 4: The "Move or Pay" logic
}


@MainActor
class SessionManager: ObservableObject {
    // State
    @Published var state: AppState = .disconnected
    @Published var activeError: UnitouchError? = nil
    
    // Persistent Memory
    var currentUser: UnitouchUser?
    var currentTable: TableInfo?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        TCPClient.shared.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleConnectionChange(status)
            }
            .store(in: &cancellables)
                
                TCPClient.shared.start()
    }
    
    private func handleConnectionChange(_ status: ConnectionStatus) {
        switch status {
        case .connected:
            // If we have a user and pin, try to auto-login (silent restore)
            if let user = currentUser {
                print("🔄 TCP Connected: Attempting session restore for \(user.name)...")
                
                
            } else {
                // Otherwise, just fetch the user list for a fresh start
                print("🔄 TCP Connected: Fetching users...")
                self.state = .userSelection
            }
            
        case .disconnected, .failed:
            self.state = .disconnected
            
        case .connecting:
            self.state = .loading("Connecting...")
        }
    }
    
    
    func setUsers(user: UnitouchUser){
        TCPClient.shared.sendCommand("SET_USER \(user.id) 5") { response in
            switch response {
            case .success(let code, let message):
                print("Success! Code: \(code), message: \(message)")
                self.state = .main
                self.currentUser = user
            case .content(let data):
                self.activeError = .unknown(err: "Invalid response to command SETUSR")
            case .error(let error):
                self.activeError = .unknown(err: error.localizedDescription)
            }
        }
    }
    
    
    
    
    
}
