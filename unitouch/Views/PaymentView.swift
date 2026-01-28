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
    @State var backendManager = BackendManager.shared
    
    @State private var bill: String? = nil
    @State private var hasFocused: Bool = false
    
    @State private var input: String = ""
    @State private var display: String = ""
    
    
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
                    Text(bill ?? "")
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height - (itemSize*3) )
                        .background(.white)
                        .foregroundStyle(.black)
                        .onAppear {
                            Task {
                                if bill == nil {
                                    bill = await backendManager.getBill()
                                }
                            }
                        }
                    Spacer()
                    VStack(alignment: .center){
                        HStack {
                            Text("Rekening")
                                .font(.title)
                                .bold()
                                .frame(maxWidth: itemSize, maxHeight: textHeight)
                            
                            Text(String(format: "%.2f", (backendManager.balance ?? 0) ) )
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
                                Text( (Int(input) ?? 0)  == 0 ? "0.00" : display)
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
                                
                                TextField("", text: $input)
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
                                    .onChange(of: input) { _, newValue in
                                        let cleanedInput = input.filter { "0123456789".contains($0) }
                                        
                                        if newValue != cleanedInput {
                                            self.input = cleanedInput
                                        }
                                        
                                        if hasFocused {
                                            self.display = String(format: "%.2f", ((Double(cleanedInput) ?? 0) / 100) )
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
                            Text( String(format: "%.2f", ( (backendManager.balance ?? 0) + (Double(display) ?? 0)) ) )
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
            SelectionButton(text: "Terug", width: itemSize, height: buttonHeight)
                            { Task { await backendManager.cancelPayment()} }
            SelectionButton(text: "Contant", width: itemSize, height: buttonHeight)
                                { Task { await backendManager.finishPayment(method: "1\tContant")} }
            SelectionButton(text: "Viva Wallet", width: itemSize, height: buttonHeight,
                            action2: {
                                Task {
                                    await backendManager.finishPayment(method: "97\tViva Wallet")
                                }
                            })
                                {  backendManager.vivaPayment(amount: String(Int( ((backendManager.balance ?? 0) + (Double(display) ?? 0))*100 ) ))}
        }
    }
        
}
