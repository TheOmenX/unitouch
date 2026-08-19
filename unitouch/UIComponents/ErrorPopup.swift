//
//  ErrorPopup.swift
//  unitouch
//
//  Created by Tijn Giesberts on 16/05/2026.
//

import SwiftUI

struct ErrorPopup: View {
    var error: UnitouchError
    var close: () -> Void = {}
    
    var body: some View {
        VStack{
            Circle()
                .foregroundStyle(Color.danger[500].opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay (
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.danger[500])
                )
                .padding(.bottom, 10)
                .padding(.top, 25)
            
            Text(error.title)
                .font(.custom("Roboto-Bold", size: 26))
                .foregroundStyle(Color.background[0])
            
            Text(error.description)
                .font(.custom("Roboto-Regular", size: 18))
                .foregroundStyle(Color.background[450])
                .padding(.top, 5)
                .padding(.horizontal, 24)
                .multilineTextAlignment(.center)
            
            PrimaryFilledButton(action: {
                close()
            }) {
                Text("Ok")
            }.padding(24)

        }
        .background(
            LinearGradient(
                colors: [Color.danger[500].opacity(0.15), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    HStack{
        Text("")
    }.popup(isPresented: .constant(true), content: {
        ErrorPopup(error: .unknown(err: "Test Error"), close: {})
    })
}
