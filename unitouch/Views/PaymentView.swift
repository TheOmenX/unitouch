//
//  PaymentView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 8/5/25.
//

import SwiftUI
import UIKit
import Combine

struct PaymentView: View {
    @ObservedObject var session: SessionManager
    
    var balance: Double
    var bill: String
    
    @State private var fooiInput: String = ""
    
    private var fooi: Double {
        if let fooi = Double(fooiInput) {
            return fooi/100
        }else {
            return 0.00
        }
    }
    
    @State private var hasFocused: Bool = false
    
    
    var body: some View {
        ZStack{
            GeometryReader { geometry in
                let columns = 3
                let spacing: CGFloat = 8
                let totalSpacing = spacing * CGFloat(columns - 1)
                let itemSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
                let buttonHeight = (geometry.size.width - totalSpacing) / CGFloat(4)
                let textHeight = (geometry.size.width - totalSpacing) / CGFloat(5)
                
                VStack {
                    Text(bill)
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height - (itemSize*3) )
                        .background(.white)
                        .foregroundStyle(.black)
                    Spacer()
                    VStack(alignment: .center){
                        HStack {
                            Text("Rekening")
                                .font(.title)
                                .bold()
                                .frame(maxWidth: itemSize, maxHeight: textHeight)
                            
                            Text(String(format: "%.2f", self.balance ) ) // TODO: backendManager.balance
                                .font(.largeTitle)
                                .padding()
                                .frame(width: itemSize * 2)
                                .frame(maxHeight: textHeight)
                                .background(Color(.white))
                                .foregroundStyle(.black)
                                .cornerRadius(8)
                        }
                        HStack {
                            Text("Fooi")
                                .font(.title)
                                .bold()
                                .frame(width: itemSize)
                                .frame(maxHeight: textHeight)
                            // Display the current input as a currency format
                            
                            ZStack{
                                Text(String(format: "%.2f", self.fooi))
                                    .font(.largeTitle)
                                    .padding()
                                    .frame(width: (itemSize*2)-8)
                                    .frame(maxHeight: textHeight)
                                    .background(Color(.white))
                                    .foregroundStyle(.black)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: 8)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black, lineWidth: 3)
                                    )
                                
                                TextField("", text: $fooiInput)
                                    .keyboardType(.numberPad)
                                    .frame(maxWidth: .infinity)
                                    .frame(maxHeight: textHeight)
                                    .tint(.clear)
                                    .font(.system(size: 0))
                                    .foregroundStyle(.clear)
                                    .onTapGesture {
                                        if !hasFocused {
                                            // Trigger logic only on first focus
                                            hasFocused = true
                                        }
                                    }
                                    .onChange(of: fooiInput) { _, newValue in
                                        let cleanedInput = fooiInput.filter { "0123456789".contains($0) }
                                        if newValue != cleanedInput {
                                            self.fooiInput = cleanedInput
                                        }
                                    }
                            }
                            .frame(width: itemSize * 2)
                            
                            
                        }
                        HStack {
                            Text("Totaal")
                                .font(.title)
                                .bold()
                                .frame(width: itemSize)
                                .frame(maxHeight: textHeight)
                            Text( String(format: "%.2f", (fooi != 0 ? fooi : balance) ) ) // TODO: backendManager.balance
                                .font(.largeTitle)
                                .padding()
                                .frame(width: itemSize * 2)
                                .frame(maxHeight: textHeight)
                                .background(Color(.white))
                                .foregroundStyle(.black)
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                    paymentButtons(itemSize: itemSize, buttonHeight: buttonHeight)
                    
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    @ViewBuilder
    private func paymentButtons(itemSize: CGFloat, buttonHeight: CGFloat) -> some View {
        HStack{
            SelectionButton(text: "Terug",
                            width: itemSize,
                            height: buttonHeight,
                            action1:{
                                session.closeTable()
                            })
            SelectionButton(text: "Contant",
                            width: itemSize,
                            height: buttonHeight,
                            disabled: (fooi != 0 && fooi < balance),
                            action1: {
                session.finishPayment(methodId: 1, methodName: "Contant")
                            })
            SelectionButton(text: "Viva Wallet",
                            width: itemSize,
                            height: buttonHeight,
                            disabled: (fooi != 0 && fooi < balance),
                            action2: {
                                session.finishPayment(methodId: 2, methodName: "Viva Wallet")
                            }, action1: {
                                session.vivaPayment(amount: balance, total: fooi)
                            })
        }
    }
        
}
