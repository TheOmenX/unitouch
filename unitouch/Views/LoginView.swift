//
//  LoginView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 24/05/2025.
//

import SwiftUI

struct LoginView: View {
    
    let users: [UnitouchUser]
    let onSelect: (UnitouchUser) -> Void
    let onFail: () -> Void
    
    @State private var selectedUser: UnitouchUser? = nil
    @State private var showAlert: Bool = false
    @State private var passwordText: String = ""
    
    var body: some View {
        ZStack {
            List(users.sorted {$0.id < $1.id}, id: \.self) { user in
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
                            if passwordText != user.password {
                                onFail()
                            }else {
                                onSelect(user)
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

