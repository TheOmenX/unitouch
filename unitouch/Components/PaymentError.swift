//
//  PaymentComplete 2.swift
//  unitouch
//
//  Created by Tijn Giesberts on 05/05/2026.
//


//
//  PaymentComplete.swift
//  unitouch
//
//  Created by Tijn Giesberts on 01/04/2026.
//

import SwiftUI

struct PaymentError: View {
    var amount: Double
    var retry: () -> Void = {}
    var close: () -> Void = {}
    
    var body: some View {
        VStack{
            ZStack {
                LinearGradient(colors: [Color.danger[500].opacity(0.25), Color.clear], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .center) {
                    Circle()
                        .foregroundStyle(Color.danger[500].opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay (
                            Image(systemName: "x.circle")
                                .font(.system(size: 52))
                                .foregroundStyle(Color.danger[500])
                        )
                    Text("FOUT BIJ BETALING")
                        .font(.custom("Roboto-Bold", size: 18))
                        .foregroundStyle(Color.primary[500])
                        .padding(.top, 5)
                    Text("\((amount).formatted(.currency(code: "EUR")))")
                        .padding(.vertical, 2)
                        .font(.custom("Roboto-Bold", size: 32))
                        .strikethrough()
                        
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
                    Text("Rekening")
                        .font(.custom("Roboto-Regular", size: 16))
                        .foregroundStyle(Color.background[400])
                    Spacer()
                    
                    Text("\(amount.formatted(.currency(code: "EUR")))")
                        .font(.custom("Roboto-Bold", size: 16))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.background[750].opacity(0.3))
                .cornerRadius(16)
                
                /*HStack{
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
                .cornerRadius(16)*/
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            
            PrimaryFilledButton(action: {
                close()
            }) {
                Text("DOORGAAN")
            }.padding()
            
                
            
        }
        
    }
}

#Preview {
    HStack{
        Text("")
    }.popup(isPresented: .constant(true), content: {
        PaymentError(
            amount: 26.00,
            retry: {
            },
            close: {
            }
        )
    })
}
