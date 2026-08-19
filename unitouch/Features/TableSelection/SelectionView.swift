//
//  SelectionView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 3/5/25.
//

import SwiftUI
import Combine

struct SelectionView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var store: RestaurantStore
    
    @State private var tableString: String = ""
    
    var tableInfo: (Int, Int) {
        let pattern = #"^(?!\.)(\d{0,4})(?:\.(\d?))?$"#
        
        guard let match = tableString.range(of: pattern, options: .regularExpression) else {
            return (0, 0)
        }
        
        let components = tableString[match].split(separator: ".")
        let tableNum = Int(components[0]) ?? 0
        let splitIndex = components.count > 1 ? Int(components[1]) ?? 0 : 0
        return (tableNum, splitIndex)
    }
    
    @State private var errorAlert: Bool = false
    @State private var itemsPresentAlert: Bool = false
    @State private var takenAlert: Bool = false
    
    @State private var tempMoveTable: String? = nil
    
    @State private var activeTab = 1
    
    var payments: [Payment]
    
    var body: some View {
        TabView(selection: $activeTab){
            OpenTablesView().tag(0)
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
            Text(tableString.isEmpty ? "\u{00A0}" : tableString)
                .padding(.vertical, 30)
                .font(.custom("Roboto-BoldItalic", size: 76))
                .foregroundStyle(Color.background[100])
            
            Divider()
                .background(Color.background[400])
                            
            InputKeypad(
                input: Binding(
                    get: { tableString },
                    set: { tableString = $0 }
                ),
                inputValidation: { input in
                    let pattern = #"^(?!\.)(\d{0,4})(?:\.(\d?))?$"#
                    return input.range(of: pattern, options: .regularExpression) != nil
                }
            ).padding(.vertical, 20)
                   
            
            if true {
                // MARK: - Table Button
                PrimaryFilledButton(action: {
                    Task {
                        print(tableInfo)
                        if tableInfo.0 != 0 {
                            if let table = store.tables.findTable(using: store, tableNum: tableInfo.0) {
                                router.navigate(to: .order(tableID: table.id, subTableIndex: tableInfo.1))
                            }else {
                                router.activeError = .unknown(err: "Table doesn't exist")
                            }
                        }else {
                            //session.startTableMap(nextState: .openTable)
                        }
                    }
                }) {
                    HStack(alignment: .center){
                        Image(systemName: "pencil.and.list.clipboard")
                        Text("Open Tafel")
                            .font(.custom("Roboto-Bold", size: 24))
                    }
                }
                
                
                HStack {
                    // MARK: - Payment Button
                    Button(action: {
                        if tableInfo.0 != 0 {
                        } else {
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
                    
                    // MARK: - Move Button
                    Button(action: {
                        //session.checkSubTable(table: tableNum, nextState: .moveTable)
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
            }
            // TODO: Fix moving table
            /*else {
                PrimaryFilledButton(action: {
                    Task {
                        if tableNum.rawTable == "" { return }
                        
//                        print ("Current table items: \(session.currentTableItems.count)")
//                        if session.currentTableItems.count > 0 {
//                            session.checkSubTable(table: tableNum, nextState: .splitTable)
//                        } else {
//                            session.checkSubTable(table: tableNum, nextState: .moveTable)
//                        }
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
                    Task {
                        try? await NetworkService.shared.unlockTable(tableId: <#T##String#>, subTable: <#T##Int#>)
                        router.navigate(to: .main)
                    }
                }) {
                    HStack(alignment: .center){
                        Image(systemName: "xmark")
                        Text("Annuleren")
                            .font(.custom("Roboto-Bold", size: 24))
                    }
                }
            }*/
            
        }
        .padding()
        .popup(item: $router.requestMoveConformation) { item in
            VStack{
                Text("Tafel verplaatsen?")
                    .font(.custom("Roboto-Bold", size: 24))
                Text("Doel heeft al items, wilt u verder gaan?")
                    .font(.custom("Roboto-Regular", size: 16))
                    
                HStack{
                    BlankOutlineButton(action: {router.requestMoveConformation = nil}) {
                        Text("Annuleren")
                    }
                    PrimaryFilledButton(action: {
                        // TODO: fix splitting tables -
//                        if .currentTableItems.isEmpty {
//                            session.finishMoveTable(newTable: item)
//                        } else {
//                            session.finishSplitTable(newTable: item)
//                        }
                    }) {
                        Text("Bevestigen")
                    }
                }.padding(.top, 12)
            }
            .padding()
        }
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
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var store: RestaurantStore
    
    @State private var openTables: [Components.Schemas.TableSearchResult] = []
        
    
    var body: some View {
        VStack{
            HStack(alignment: .center){
                Text("Openstaande Tafels")
                    .font(.custom("Roboto-Bold", size: 32))
                    .foregroundStyle(Color.background[100])
                    .padding()
            }
            ScrollView {
                ForEach(openTables, id: \.id) { table in
                    HStack {
                        VStack{
                            HStack{
                                Text(table.resolvedTable(in: store)?.label ?? "Tafel")
                                    .font(.custom("Roboto-Bold", size: 18))
                                    .foregroundStyle(Color.background[100])
                            }
                            HStack(spacing: 0){
                                Image(systemName: "clock")
                                    .font(.system(size: 14)) // keep icon size consistent
                                    .foregroundStyle(Color.background[400])
                                Text(table.edited_at, style: .time)
                                    .foregroundStyle(Color.background[400])
                                    .font(.custom("Roboto-Regular", size: 14))
                            }
                        }
                        
                        Spacer()
                        
                        if table.locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.danger[500])
                        }
                        
                        Spacer()
                        
                        Text(table.total_price.formatted(.currency(code: "EUR")))
                            .font(.custom("Roboto-Bold", size: 18))
                            .foregroundStyle(Color.background[100])
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        router.navigate(to: .order(tableID: table.id, subTableIndex: table.sub_table))
                    }
                    Divider()
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                }
                            
            }
        }
        .onAppear {
            Task {
                if let tables = try? await NetworkService.shared.getOpenTables() {
                    self.openTables = tables
                }
            }
        }
    }
}


