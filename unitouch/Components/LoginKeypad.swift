//
//  LoginKeypad.swift
//  unitouch
//
//  Created by Tijn Giesberts on 27/03/2026.
//

import SwiftUI

struct LoginKeypad: View {
    var passcodeLength: Int = 3
    var onComplete: ((String) -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    @State private var passcode: String = ""
    
    var body: some View {
        ZStack {
            //Color.background[800]
            VStack {
                Text("Login Required")
                    .font(.title)
                    .bold()
                Text("Enter Your Personal Passcode Below")
                    .font(.subheadline)
                    .foregroundColor(.background[100])
                    
                HStack{
                    ForEach(1...passcodeLength, id: \.self) { i in
                        Circle()
                            .fill(i <= passcode.count ? Color.primary[500] : Color.background[800])
                            .overlay(Circle().stroke(Color.background[400], lineWidth: 2))
                            .frame(width: 15, height: 15)
                    }
                        
                }
                .padding(.vertical, 40)
                VStack{
                    ForEach(1...3, id: \.self) { row in
                        HStack{
                            ForEach(1...3, id: \.self) { column in
                                let number = (row - 1) * 3 + column
                                Button(action: {
                                    if passcode.count < passcodeLength {
                                        passcode.append("\(number)")
                                    }
                                }) {
                                    Text("\(number)")
                                        .frame(width: 70, height: 70)
                                        .background(Color.background[700])
                                        .cornerRadius(37.5)
                                        .bold()
                                }.padding(3)
                            }
                        }
                    }
                    
                    HStack{
                        Button(action: {}) {
                            Text("").frame(width: 70, height: 70)
                        }.padding(3)
                        
                        Button(action: {
                            if passcode.count < passcodeLength {
                                passcode.append("0")
                            }
                        }) {
                            Text("0")
                                .frame(width: 70, height: 70)
                                .background(Color.background[700])
                                .cornerRadius(37.5)
                                .bold()
                        }.padding(3)
                        
                        Button(action: {
                            if passcode.count > 0 {
                                passcode.removeLast()
                            }
                        }) {
                            Image(systemName: "delete.left")
                                .frame(width: 70, height: 70)
                                .foregroundStyle(.red)
                                .font(.system(size: 30))
                                
                        }.padding(3)
                        
                    }
                }
                
                
                // Confirm Login
                Button(action: {
                    onComplete?(passcode)
                }) {
                    Text("Login to Terminal")
                        .padding(.horizontal, 80)
                        .padding(.vertical, 20)
                        .background(passcode.count == passcodeLength ? Color.primary[500]  : Color.primary[800])
                        .foregroundColor(passcode.count == passcodeLength ? Color.background[1000] : Color.background[500])
                        .cornerRadius(15)
                        .bold()
                        .font(.system(size: 20))
                        .shadow(color: passcode.count == passcodeLength ? Color.primary[500].opacity(0.5) : Color.clear, radius: 10, x: 0, y: 0)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Cancel login
                Button(action: {
                    onCancel?()
                }){
                    Text("Cancel")
                        .bold()
                        .foregroundColor(.background[100])
                }
                
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
    }
}

#Preview {
    LoginKeypad()
}
