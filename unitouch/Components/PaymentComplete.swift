//
//  PaymentComplete.swift
//  unitouch
//
//  Created by Tijn Giesberts on 01/04/2026.
//

import SwiftUI

struct PaymentComplete: View {
    var amount: Decimal
    
    var body: some View {
        VStack{
            ZStack {
                LinearGradient(colors: [Color.primary[500].opacity(0.15), Color.clear], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .center) {
                    Circle()
                        .foregroundStyle(Color.primary[800].opacity(0.5))
                        .frame(width: 100, height: 100)
                        .overlay (
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 52))
                                .foregroundStyle(Color.primary[500])
                        )
                    Text("BETALING VOLTOOID")
                        .font(.custom("Roboto-Bold", size: 18))
                        .foregroundStyle(Color.primary[500])
                        .padding(.top, 5)
                    Text("€ \(amount.toCurrency)")
                        .padding(.vertical, 2)
                        .font(.custom("Roboto-Bold", size: 32))
                }
            }
            .frame(maxHeight: 300)
            
            VStack(alignment: .leading) {
                Text("TRANSACTIE DETAILS")
                    .font(.custom("Roboto-Bold", size: 14))
                    .foregroundStyle(Color.background[400])
                
                HStack{
                    Image(systemName: "number")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primary[500])
                    Text("ID")
                        .font(.custom("Roboto-Regular", size: 16))
                        .foregroundStyle(Color.background[400])
                    Spacer()
                    
                    Text("")
                        .font(.custom("Roboto-Bold", size: 16))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.background[750].opacity(0.3))
                .cornerRadius(16)
                
                HStack{
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primary[500])
                    Text("Tijd")
                        .font(.custom("Roboto-Regular", size: 16))
                        .foregroundStyle(Color.background[400])
                    Spacer()
                    
                    Text("Oct 24, 2023 • 14:32")
                        .font(.custom("Roboto-Bold", size: 16))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.background[750].opacity(0.3))
                .cornerRadius(16)
                
                HStack{
                    Image(systemName: "creditcard")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primary[500])
                    Text("Methode")
                        .font(.custom("Roboto-Regular", size: 16))
                        .foregroundStyle(Color.background[400])
                    Spacer()
                    
                    Text("")
                        .font(.custom("Roboto-Bold", size: 16))
                    
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.background[750].opacity(0.3))
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
                
            
        }
        
    }
}

#Preview {
    HStack{
        Text("")
    }.popup(isPresented: .constant(true), content: {
        PaymentComplete(amount: 23.56)
    })
}
