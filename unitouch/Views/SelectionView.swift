//
//  SelectionView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 3/5/25.
//

import SwiftUI
import Combine

struct SelectionView: View {
    @ObservedObject var session: SessionManager
    
    @State private var tableNum: TableInfo = TableInfo(rawTable: "")
    
    @State private var errorAlert: Bool = false
    @State private var itemsPresentAlert: Bool = false
    @State private var takenAlert: Bool = false
    
    @State private var tempMoveTable: String? = nil
    
    var payments: [Payment]
    
    var body: some View {
        TabView{
            selectionView
            PaymentListView(payments: payments)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
        
        
    var selectionView: some View {
        VStack{
            Text("CURRENT SELECTION")
                .font(.custom("Roboto-Regular", size: 16))
                .foregroundStyle(Color.background[100])
                .padding(.top, 8)
            Text(tableNum.rawTable.isEmpty ? "\u{00A0}" : tableNum.rawTable)
                .padding(.vertical, 30)
                .font(.custom("Roboto-BoldItalic", size: 76))
            
            Divider()
                .background(Color.background[400])
                            
            InputKeypad(
                input: Binding(
                    get: { tableNum.rawTable },
                    set: { tableNum.rawTable = $0 }
                ),
                inputValidation: { input in
                    return TableInfo.validTableInput(tableString: input)
                }
            ).padding(.vertical, 20)
                   
            
            if session.currentTable == nil {
                Button(action: {
                    Task {
                        if(session.currentTable != nil){
                            if session.currentTableItems.count > 0 {
                                session.checkSubTable(table: tableNum, nextState: .splitTable)
                            } else {
                                session.checkSubTable(table: tableNum, nextState: .moveTable)
                            }
                        }else{
                            if tableNum.table != 0 {
                                session.checkSubTable(table: tableNum, nextState: .openTable)
                            }else {
                                session.startTableMap(nextState: .openTable)
                            }
                        }
                        tableNum.rawTable = ""
                    }
                }) {
                    HStack(alignment: .center){
                        Image(systemName: "pencil.and.list.clipboard")
                        Text("Open Table")
                            .font(.custom("Roboto-Bold", size: 24))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.primary[500] )
                    .foregroundColor(Color.background[1000])
                    .cornerRadius(12)
                    .shadow(color: Color.primary[500].opacity(0.2), radius: 5, x: 0, y: 0)
                }
                
                HStack {
                    Button(action: {
                        if tableNum.table != 0 {
                            session.startPayment(table: tableNum)
                        } else {
                            session.startTableMap(nextState: .payTable)
                        }
                    }) {
                        HStack{
                            Image(systemName: "eurosign")
                            Text("Pay")
                                .font(.custom("Roboto-Bold", size: 24))
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .cornerRadius(12)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.background[700], lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: {
                        session.checkSubTable(table: tableNum, nextState: .moveTable)
                        tableNum.rawTable = ""
                    }) {
                        HStack{
                            Image(systemName: "arrow.right.arrow.left")
                            Text("Move")
                                .font(.custom("Roboto-Bold", size: 24))
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .cornerRadius(12)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.background[700], lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.leading, 8)
                    }
                }
            } else {
                
            }
            
        }
        .padding()
    }
    
    
    func addTableNum(_ symbol: String) {
        if tableNum.rawTable.contains(".") {
            if symbol == "." { return } // Already a dot in the string
            if tableNum.rawTable.firstIndex(of: ".").map({ $0 != tableNum.rawTable.index(before: tableNum.rawTable.endIndex) }) ?? true { return } // Only one character after dot
        } else if tableNum.rawTable.count > 3 && symbol != "." { // Only 4 symbols before dot
            return
        } else if symbol == "." && tableNum.rawTable.count == 0 { // Can't start with dot
            return
        }
        
        tableNum.rawTable += symbol
    }
}


struct PaymentListView: View {
    var payments: [Payment]
    
    // 1. Create a structured tuple for our grouped data
    var groupedPayments: [(date: Date, payments: [Payment], totalTips: Decimal)] {
        // Group by the start of the day (ignoring time)
        let grouped = Dictionary(grouping: payments) { payment in
            Calendar.current.startOfDay(for: payment.time)
        }
        
        // Map the dictionary into our tuple and calculate the total tips
        return grouped.map { (date, dailyPayments) in
            let totalTips = dailyPayments.reduce(Decimal(0)) { $0 + $1.tip }
            return (date: date, payments: dailyPayments, totalTips: totalTips)
        }
        // Sort by date, newest first
        .sorted { $0.date > $1.date }
    }
    
    var body: some View {
            NavigationStack {
                List {
                    // Loop through the groups (days)
                    ForEach(groupedPayments, id: \.date) { group in
                        
                        // Create a Section for each day
                        Section(header: sectionHeader(date: group.date, totalTips: group.totalTips)) {
                            
                            // Loop through the individual payments for that day
                            ForEach(group.payments) { payment in
                                HStack {
                                    // Show just the time for the individual row
                                    Text(payment.time, format: .dateTime.hour().minute())
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Tafel \(payment.table)")
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(payment.amount.formatted(.currency(code: "EUR")))
                                            .bold()
                                        if payment.tip > 0 {
                                            Text("Fooi: \(payment.tip.formatted(.currency(code: "EUR")))")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Transacties")
            }
        }
        
        // Extracted the header to keep the code clean
        @ViewBuilder
        private func sectionHeader(date: Date, totalTips: Decimal) -> some View {
            HStack {
                // Display the date (e.g., "Oct 24, 2023")
                Text(date, format: .dateTime.month().day().year())
                    .font(.headline)
                
                Spacer()
                
                // Display the total tips for this day
                Text("Totale fooi: \(totalTips.formatted(.currency(code: "EUR")))")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 4)
        }
}


