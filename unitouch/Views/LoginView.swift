//
//  LoginView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 24/05/2025.
//

import SwiftUI

struct LoginView: View {
    @State var backendManager = BackendManager.shared
    
    @State private var selectedUser: UnitouchUser? = nil
    @State private var showAlert: Bool = false
    @State private var passwordText: String = ""
    
    var body: some View {
        ZStack {
            List(backendManager.backendData.users.sorted {$0.id < $1.id}, id: \.self) { user in
                HStack{
                    Text(user.name)
                }
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading) // Stretch full width
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedUser = user
                    showAlert = true
                }
            }
            .listStyle(.plain)
            
            if(showAlert){
                CustomAlertView(
                    title: "Login",
                    description: "",
                    cancelAction: {
                        // Cancel action here
                        withAnimation {
                            showAlert.toggle()
                        }
                    },
                    cancelActionTitle: "Annuleren",
                    primaryAction: {
                        // Primary action here
                        Task{
                            guard let user = selectedUser else { return }
                            do {
                                try await backendManager.login(user: user)
                                backendManager.appState = .selection
                            } catch {
                                print("Invalid password")
                            }
                        }
                        
                        withAnimation {
                            showAlert.toggle()
                        }
                    },
                    primaryActionTitle: "Log In",
                    inputText: $passwordText
                )
            }
        }
    }
}

