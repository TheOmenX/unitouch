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
    
    @State private var activeTab = 1
    
    var payments: [Payment]
    
    var body: some View {
        TabView(selection: $activeTab){
            OpenTablesView(session: session).tag(0)
            selectionView.tag(1)
            PaymentListView(payments: payments).tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
        
        
    var selectionView: some View {
        VStack{
            Text("HUIDIGE SELECTIE")
                .font(.custom("Roboto-Regular", size: 16))
                .foregroundStyle(Color.background[100])
                .padding(.top, 8)
            Text(tableNum.rawTable.isEmpty ? "\u{00A0}" : tableNum.rawTable)
                .padding(.vertical, 30)
                .font(.custom("Roboto-BoldItalic", size: 76))
                .foregroundStyle(Color.background[100])
            
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
                PrimaryFilledButton(action: {
                    Task {
                        if tableNum.table != 0 {
                            session.checkSubTable(table: tableNum, nextState: .openTable)
                        }else {
                            session.startTableMap(nextState: .openTable)
                        }
                        tableNum.rawTable = ""
                    }
                }) {
                    HStack(alignment: .center){
                        Image(systemName: "pencil.and.list.clipboard")
                        Text("Open Tafel")
                            .font(.custom("Roboto-Bold", size: 24))
                    }
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
                            Text("Betalen")
                                .font(.custom("Roboto-Bold", size: 18))
                            
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
                            Text("Verplaatsen")
                                .font(.custom("Roboto-Bold", size: 18))
                            
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
                PrimaryFilledButton(action: {
                    Task {
                        if tableNum.rawTable == "" { return }
                        
                        print ("Current table items: \(session.currentTableItems.count)")
                        if session.currentTableItems.count > 0 {
                            session.checkSubTable(table: tableNum, nextState: .splitTable)
                        } else {
                            session.checkSubTable(table: tableNum, nextState: .moveTable)
                        }
                        tableNum.rawTable = ""
                    }
                }) {
                    HStack(alignment: .center){
                        Image(systemName: "arrow.right.arrow.left")
                        Text("Verplaats Tafel")
                            .font(.custom("Roboto-Bold", size: 24))
                    }
                }.opacity(tableNum.rawTable == "" ? 0.5 : 1)
                
                BlankOutlineButton(action: {
                    session.closeTable()
                    tableNum.rawTable = ""
                }) {
                    HStack(alignment: .center){
                        Image(systemName: "xmark")
                        Text("Annuleren")
                            .font(.custom("Roboto-Bold", size: 24))
                    }
                }
            }
            
        }
        .padding()
        .popup(item: $session.requestMoveConformation) { item in
            VStack{
                Text("Tafel verplaatsen?")
                    .font(.custom("Roboto-Bold", size: 24))
                Text("Doel heeft al items, wilt u verder gaan?")
                    .font(.custom("Roboto-Regular", size: 16))
                    
                HStack{
                    BlankOutlineButton(action: {session.requestMoveConformation = nil}) {
                        Text("Annuleren")
                    }
                    PrimaryFilledButton(action: {
                        if session.currentTableItems.isEmpty {
                            session.finishMoveTable(newTable: item)
                        } else {
                            session.finishSplitTable(newTable: item)
                        }
                    }) {
                        Text("Bevestigen")
                    }
                }.padding(.top, 12)
            }
            .padding()
        }
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
    
    @State private var uncollapsedDates: Set<Date> = [Calendar.current.startOfDay(for: Date())]
    
    // 1. Create a structured tuple for our grouped data
    var groupedPayments: [(date: Date, payments: [Payment], totalTips: Decimal)] {
        // Group by the start of the day (ignoring time)
        let grouped = Dictionary(grouping: payments) { payment in
            Calendar.current.startOfDay(for: payment.time)
        }
        
        // Map the dictionary into our tuple and calculate the total tips
        return grouped.map { (date, dailyPayments) in
            let totalTips = dailyPayments.reduce(Decimal(0)) { $0 + $1.tip }
            let payments = dailyPayments.sorted { $0.time > $1.time }
            return (date: date, payments: payments, totalTips: totalTips)
        }
        // Sort by date, newest first
        .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack{
            HStack(alignment: .center){
                Text("Transacties")
                    .font(.custom("Roboto-Bold", size: 32))
                    .foregroundStyle(Color.background[100])
                    .padding()
            }
            ScrollView{
                ForEach(groupedPayments, id: \.date) { group in
                    
                    // Use the same visual header but make it tappable to toggle collapsed state
                    Section(header:
                        Button(action: {
                            withAnimation {
                                if uncollapsedDates.contains(group.date) {
                                    uncollapsedDates.remove(group.date)
                                } else {
                                    uncollapsedDates.insert(group.date)
                                }
                            }
                        }) {
                            sectionHeader(date: group.date, totalTips: group.totalTips)
                        }
                        .buttonStyle(.plain)
                    ) {
                        // Only show the payments when not collapsed — keeps exact existing look
                        if uncollapsedDates.contains(group.date) {
                            ForEach(group.payments) { payment in
                                HStack {
                                    VStack{
                                        HStack{
                                            Text("Tafel \(payment.table)")
                                                .font(.custom("Roboto-Bold", size: 18))
                                                .foregroundStyle(Color.background[100])
                                        }
                                        HStack(spacing: 0){
                                            Image(systemName: "clock")
                                                .font(.system(size: 14)) // keep icon size consistent
                                                .foregroundStyle(Color.background[400])
                                            Text(payment.time, format: .dateTime.hour().minute())
                                                .foregroundStyle(Color.background[400])
                                                .font(.custom("Roboto-Regular", size: 14))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(payment.amount.formatted(.currency(code: "EUR")))
                                            .font(.custom("Roboto-Bold", size: 18))
                                            .foregroundStyle(Color.background[100])
                                        if payment.tip > 0 {
                                            Text("Fooi: \(payment.tip.formatted(.currency(code: "EUR")))")
                                                .font(.custom("Roboto-Regular", size: 14))
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                Divider()
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Extracted the header to keep the code clean
    @ViewBuilder
    private func sectionHeader(date: Date, totalTips: Decimal) -> some View {
        VStack{
            Divider()
                .frame(maxWidth: .infinity)
                .background(Color.background[700])
            
            HStack {
                Text(date.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                    .font(.custom("Roboto-Bold", size: 20))
                    .foregroundStyle(Color.background[400])
                
                Spacer()
                
                Text("Totale fooi:")
                    .font(.custom("Roboto-Regular", size: 14))
                    .foregroundStyle(Color.background[400])
                Text("\(totalTips.formatted(.currency(code: "EUR")))")
                    .font(.custom("Roboto-Bold", size: 14))
                    .foregroundStyle(.green)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 99)
                            .stroke(Color.background[700], lineWidth: 1)
                    )
                    
            }
            .padding(.horizontal, 12)
            .background(Color.background[800])
            
            Divider()
                .frame(maxWidth: .infinity)
                .background(Color.background[700])
        }
        .background(Color.background[800])
    }
}

struct OpenTablesView: View {
    @ObservedObject var session: SessionManager
    
    var body: some View {
        VStack{
            HStack(alignment: .center){
                Text("Openstaande Tafels")
                    .font(.custom("Roboto-Bold", size: 32))
                    .foregroundStyle(Color.background[100])
                    .padding()
            }
            ScrollView {
                ForEach(session.openTables, id: \.id) { table in
                    HStack {
                        VStack{
                            HStack{
                                Text("Tafel \(table.tableInfo.formatTableRaw)")
                                    .font(.custom("Roboto-Bold", size: 18))
                                    .foregroundStyle(Color.background[100])
                            }
                            HStack(spacing: 0){
                                Image(systemName: "clock")
                                    .font(.system(size: 14)) // keep icon size consistent
                                    .foregroundStyle(Color.background[400])
                                Text(table.time)
                                    .foregroundStyle(Color.background[400])
                                    .font(.custom("Roboto-Regular", size: 14))
                            }
                        }
                        
                        Spacer()
                        if table.comment != "" {
                            Text(table.comment)
                                .font(.custom("Roboto-Bold", size: 16))
                                .foregroundStyle(Color.primary[500])
                                
                        }
                        Spacer()
                        
                        Text(table.balance.formatted(.currency(code: "EUR")))
                            .font(.custom("Roboto-Bold", size: 18))
                            .foregroundStyle(Color.background[100])
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        session.enterTable(table: table.tableInfo)
                    }
                    Divider()
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                }
                            
            }
        }
        .onAppear {
            session.getOpenTables()
        }
    }
}


