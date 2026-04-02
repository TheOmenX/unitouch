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
    
    @State private var recentUser: UnitouchUser? = nil
    @State private var selectedUser: UnitouchUser? = nil
    @State private var showAlert: Bool = false
    @State private var passwordText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Welcome Back")
                    .font(.custom("Roboto-Bold", size: 34, relativeTo: .largeTitle))
                    .padding(.top, 24)
                    .padding(.bottom, 2)
                
                Text("Select your identity to unlock the terminal.")
                    .font(.custom("Roboto-Regular", size: 17, relativeTo: .body))
                    .foregroundStyle(Color.background[100])
                
                if recentUser != nil {
                    HStack{
                        Rectangle()
                            .frame(width: 18, height: 5)
                            .foregroundStyle(Color.primary[500])
                        Text("QUICK ACCESS")
                            .font(.custom("Roboto-Bold", size: 13, relativeTo: .footnote)) // Looks like a small header, footprint size fits best here
                            .foregroundStyle(Color.background[100])
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 6)
                    
                    HStack(alignment: .center){
                        HStack{
                            Image(systemName: "person")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.primary[500])
                                .frame(width: 48, height: 48)
                                .background(
                                    Color.primary[800].opacity(0.5),
                                    in: RoundedRectangle(cornerRadius: 18)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.primary[600].opacity(0.5), lineWidth: 1)
                                )
                                .padding(8)
                            
                            VStack (alignment: .leading){
                                Text("\(recentUser?.name ?? "")")
                                    .font(.custom("Roboto-Bold", size: 28, relativeTo: .title))
                                
                                Text("Tap to resume terminal access")
                                    .font(.custom("Roboto-Regular", size: 13, relativeTo: .footnote))
                                    .foregroundStyle(Color.background[100])
                            }
                        }
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.primary[500])
                            .padding(.trailing, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(Color.primary[800].opacity(0.2))
                    .cornerRadius(16)
                    .onTapGesture {
                        selectedUser = recentUser
                        showAlert = true
                    }
                }
                
                
                HStack{
                    Rectangle()
                        .frame(width: 18, height: 5)
                        .foregroundStyle(Color.background[700])
                    
                    Text("STAFF DIRECTORY")
                        .font(.custom("Roboto-Bold", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.background[100])
                }
                .padding(.top, 24)
                .padding(.bottom, 6)
                
                ForEach(users.sorted {$0.id < $1.id}, id: \.self) { user in
                    HStack{
                        Image(systemName: "person")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.background[300])
                            .frame(width: 40, height: 40)
                            .background(Color.background[600].opacity(0.5))
                            .cornerRadius(12)
                            .padding(8)
                        
                        Text("\(user.name)")
                            .font(.custom("Roboto-Bold", size: 28, relativeTo: .title))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.background[600])
                    }
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.background[600], lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18))
                    .onTapGesture {
                        selectedUser = user
                        showAlert = true
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        
        .popup(isPresented: $showAlert) {
            LoginKeypad(
                passcodeLength: selectedUser?.password.count ?? 3,
                onComplete: ({ passcode in
                    if passcode == selectedUser?.password {
                        onSelect(selectedUser!)
                    } else {
                        onFail()
                    }
                }), onCancel: {
                    showAlert = false
                }
            )
        }
        .onAppear {
            self.recentUser = DataManager.shared.load(forKey: "recentUser", as: UnitouchUser.self)
        }
    }
}
