//
//  Buttons.swift
//  unitouch
//
//  Created by Tijn Giesberts on 02/04/2026.
//

import SwiftUI

struct BlankOutlineButton<Content: View>: View {
    var action: () -> Void
    var content: () -> Content
    
    init(action: @escaping () -> Void = {}, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
                .font(.custom("Roboto-Bold", size: 24))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
        }
        .background(Color.background[900])
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.background[700], lineWidth: 1)
        )
    }
}

struct PrimaryFilledButton<Content: View>: View {
    var action: () -> Void
    var content: () -> Content
    
    init(action: @escaping () -> Void = {}, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
                .font(.custom("Roboto-Bold", size: 24))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .shadow(color: Color.primary[500].opacity(0.5), radius: 10, x: 0, y: 0)
        }
        .background(Color.primary[500])
        .foregroundColor(.black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .cornerRadius(8)
    }
}


#Preview {
    VStack{
        BlankOutlineButton(action: {}) {
            Text("Button")
        }
        HStack(spacing: 6){
            PrimaryFilledButton(action: {}){
                Text("Button")
            }
            PrimaryFilledButton(action: {}){
                Text("Button")
            }
        }
    }.padding(6)
}
