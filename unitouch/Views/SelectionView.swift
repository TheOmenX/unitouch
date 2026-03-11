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
        ZStack{
            GeometryReader { geometry in
                let columns = 4
                let spacing: CGFloat = 8
                let totalSpacing = spacing * CGFloat(columns - 1)
                let itemSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
                
                VStack(alignment: .trailing) {
                    HStack(alignment: .bottom){
                        if(session.currentTable != nil) {
                            Text("Verplaats naar")
                                .font(.caption)
                        }
                        
                        ZStack {
                            Text(tableNum.rawTable)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundColor(.black)
                                .font(.title2)
                        }
                        .frame(maxWidth: itemSize*3+spacing*2, minHeight: itemSize, maxHeight: itemSize)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    
                    
                    Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                        GridRow {
                            SelectionButton(text: "Tafel", size: itemSize, action1:  {
                                Task {
                                    if(session.currentTable != nil){
                                        if session.currentTableItems.count > 0 {
                                            session.checkSubTable(table: tableNum, nextState: .splitTable)
                                        } else {
                                            session.checkSubTable(table: tableNum, nextState: .moveTable)
                                        }
                                    }else{
                                        print(tableNum.rawTable)
                                        if tableNum.table != 0 {
                                            session.checkSubTable(table: tableNum, nextState: .openTable)
                                        }else {
                                            session.startTableMap(nextState: .openTable)
                                        }
                                    }
                                    tableNum.rawTable = ""
                                }
                            })
                            SelectionButton(text: "7", size: itemSize, action1: 
                                                {addTableNum("7")})
                            SelectionButton(text: "8", size: itemSize, action1: 
                                                {addTableNum("8")})
                            SelectionButton(text: "9", size: itemSize, action1: 
                                                {addTableNum("9")})
                        }
                        GridRow {
                            SelectionButton(text: "", size: itemSize)
                            SelectionButton(text: "4", size: itemSize, action1: 
                                                {addTableNum("4")})
                            SelectionButton(text: "5", size: itemSize, action1: 
                                                {addTableNum("5")})
                            SelectionButton(text: "6", size: itemSize, action1: 
                                                {addTableNum("6")})
                        }
                        GridRow {
                            SelectionButton(text: (session.currentTable == nil) ? "Betalen" :  "", size: itemSize, action1: {
                                if tableNum.table != 0 {
                                    session.startPayment(table: tableNum)
                                } else {
                                    session.startTableMap(nextState: .payTable)
                                }
                            })
                            SelectionButton(text: "1", size: itemSize, action1:
                                                {addTableNum("1")})
                            SelectionButton(text: "2", size: itemSize, action1: 
                                                {addTableNum("2")})
                            SelectionButton(text: "3", size: itemSize, action1: 
                                                {addTableNum("3")})
                        }
                        GridRow {
                            SelectionButton(text: (session.currentTable == nil) ? "Verpl." : "", size: itemSize, action1: {
                                session.checkSubTable(table: tableNum, nextState: .moveTable)
                                tableNum.rawTable = ""
                            })
                            SelectionButton(text: "0", size: itemSize, action1: 
                                                {addTableNum("0")})
                            SelectionButton(text: ".", size: itemSize, action1: 
                                                {addTableNum(".")})
                            SelectionButton(text: "CL", size: itemSize, action1: 
                                                {tableNum.rawTable = ""})
                        }
                        Spacer()
                        HStack{
                            SelectionButton(text: "Annuleren", width: geometry.size.width/3-6, height: geometry.size.width/4-6, action1: {
                                if session.currentTable == nil {
                                    session.logout()
                                }else {
                                    session.closeTable()
                                    tableNum.rawTable = ""
                                }
                            })
                            SelectionButton(text: "", width: geometry.size.width/3-6, height: geometry.size.width/4-6)
                            SelectionButton(text: "", width: geometry.size.width/3-6, height: geometry.size.width/4-6)
                        }
                    }
                }
            }
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


