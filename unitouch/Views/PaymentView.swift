//
//  PaymentView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 8/5/25.
//

import SwiftUI
import UIKit
import Combine

struct BillItem: Identifiable {
    var id = UUID()
    var name: String
    var price: Decimal
    var amount: Int
}

struct PaymentView: View {
    @ObservedObject var session: SessionManager
    
    @Environment(\.modelContext) private var modelContext
    
    var balance: Decimal
    var bill: String
    
    @State private var fooiInput: String = ""
    
    // 1. Add FocusState to natively track the keyboard
    @FocusState private var isInputFocused: Bool
    
    private var fooi: Decimal {
        if let fooi = Decimal(string: fooiInput) {
            return fooi/100
        } else {
            return 0.00
        }
    }
    
    @State private var hasFocused: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack{
                Text("Tafel \(session.currentTable?.formatTableRaw ?? "-")")
                    .font(.custom("Roboto-Bold", size: 18))
                    .foregroundStyle(Color.primary[500])
                
                HStack {
                    Button(action: {
                        session.closeTable()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundStyle(Color.primary[500])
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.background[800])
            
            Divider()
                .frame(maxWidth: .infinity)
                .background(Color.background[700])
            

            ScrollView {
                VStack {
                    let items = parseBill(bill: bill)
                    ForEach(items, id: \.id) { item in
                        itemContainer(item: item)
                    }
                }
                .background(Color.background[800])
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.background[700].opacity(0.3), lineWidth: 2)
                )
                .padding(12)
            }
            
            // 3. PINNED BOTTOM (Holds the totals and pushes up when the keyboard opens)
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        Text("Rekening")
                            .font(.custom("Roboto-Bold", size: 20))
                        Spacer()
                        Text("€ " + self.balance.toCurrency)
                            .font(.custom("Roboto-Bold", size: 20))
                            .foregroundStyle(Color.primary[500])
                    }
                    .padding(24)
                    
                    Divider()
                        .frame(maxWidth: .infinity)
                        .background(Color.background[700])
                    
                    HStack {
                        Text("Fooi")
                            .font(.custom("Roboto-Bold", size: 20))
                        Spacer()
                        Text("€ " + (self.fooi != 0 ? (self.fooi - self.balance).toCurrency : "0,00"))
                            .font(.custom("Roboto-Bold", size: 20))
                            .foregroundStyle(Color.primary[500])
                    }
                    .padding(24)
                    
                    Divider()
                        .frame(maxWidth: .infinity)
                        .background(Color.background[700])
                    
                    HStack {
                        Text("Totaal")
                            .font(.custom("Roboto-Bold", size: 20))
                        Spacer()
                        Text("€ " + (fooi != 0 ? fooi : balance).toCurrency)
                            .font(.custom("Roboto-Bold", size: 20))
                            .foregroundStyle(Color.primary[500])
                            .padding(10)
                            .background(Color.primary[500].opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.primary[500].opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.leading, 16)
                    .padding(.vertical, 16)
                    .padding(.trailing, 8)
                    .overlay {
                        TextField("", text: $fooiInput)
                            .keyboardType(.numberPad)
                            .focused($isInputFocused)
                            .tint(.clear)
                            .foregroundStyle(.clear)
                            .opacity(0.01)
                            .onTapGesture {
                                if !hasFocused {
                                    hasFocused = true
                                }
                                isInputFocused = true
                            }
                            .onChange(of: fooiInput) { _, newValue in
                                let cleanedInput = fooiInput.filter { "0123456789".contains($0) }
                                if newValue != cleanedInput {
                                    self.fooiInput = cleanedInput
                                }
                            }
                    }
                }
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.background[700], lineWidth: 1)
                )
                .padding(10)
                
                Divider()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                
                paymentButtons()
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    @ViewBuilder
    private func paymentButtons() -> some View {
        HStack{
            PrimaryFilledButton(action: {
                if fooi != 0 && fooi < balance { return }
                session.finishPayment(
                    methodId: 1,
                    methodName: "Contant",
                    modelContext: modelContext,
                    amount: balance,
                    tip: (fooi == 0 ? Decimal(0) : fooi - balance)
                )
            }) {
                HStack (alignment: .center, spacing: 2) {
                    Image(systemName: "eurosign.circle")
                        .font(.system(size: 18))
                    
                    Text("Contant")
                        .font(.custom("Roboto-Bold", size: 20))
                }
            }
            .opacity(self.fooi != 0 && self.fooi < balance ? 0.5 : 1)
            
            PrimaryFilledButton(action: {
                if fooi != 0 && fooi < balance { return }
                session.vivaPayment(amount: balance, total: fooi)
            }) {
                HStack (alignment: .center, spacing: 2) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 20))
                    
                    Text("Viva Wallet")
                        .font(.custom("Roboto-Bold", size: 20))
                }
            }
            .onLongPressGesture(minimumDuration: 0.7) {
                if fooi != 0 && fooi < balance { return }
                session.finishPayment(
                    methodId: 97,
                    methodName: "Viva Wallet",
                    modelContext: modelContext,
                    amount: balance,
                    tip: (fooi == 0 ? Decimal(0) : fooi - balance)
                )
            }
            .opacity(self.fooi != 0 && self.fooi < balance ? 0.5 : 1)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 30)
    }
    
    
    @ViewBuilder
    func itemContainer(item: BillItem) -> some View {
        HStack {
            Text("\(item.amount)x")
                .font(.custom("Roboto-Bold", size: 18))
                .foregroundStyle(Color.background[400])
                .frame(width: 36, height: 36)
                .background(Color.background[900])
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(item.name)
                .font(.custom("Roboto-Bold", size: 18))
            
            Spacer()
            Text("€ " + item.price.toCurrency)
        }
        .padding(10)
        
        Divider()
            .frame(maxWidth: .infinity)
            .background(Color.background[700])

    }
}

//*
func parseBill(bill: String) -> [BillItem] {
    let parts = bill.split(separator: "----------------------------------------")
    if parts.count < 2 { return [] }

    let itemsPart = parts[1]

    // Use regex ot extract the amount of items, item name and price the structure of each line is:
    // regex: ^\s*(\d+)\s+(.+?)\s+€\s*([\d,]+\,?\d*)

    let regex = try! NSRegularExpression(pattern: #"^\s*(\d+)\s+(.+?)\s+€\s*([\d,]+\,?\d*)"#, options: [])

    var items: [BillItem] = []
    let lines = itemsPart.split(separator: "\n")
    for line in lines {
        let lineStr = String(line)
        let matches = regex.matches(in: lineStr, options: [], range: NSRange(location: 0, length: lineStr.utf16.count))
        if let match = matches.first, match.numberOfRanges == 4 {
            let amountStr = (lineStr as NSString).substring(with: match.range(at: 1))
            let name = (lineStr as NSString).substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            let priceStr = (lineStr as NSString).substring(with: match.range(at: 3)).replacingOccurrences(of: ",", with: ".")
            if let amount = Int(amountStr), let price = Decimal(string: priceStr) {
                items.append(BillItem(name: name, price: price, amount: amount))
            }
        }
    }
    
    return items
    
}
 // */
