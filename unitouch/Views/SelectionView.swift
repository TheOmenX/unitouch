//
//  SelectionView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 3/5/25.
//

import SwiftUI

struct SelectionView: View {
    @State var backendManager = BackendManager.shared
    
    @State private var tableNum: TableInfo = TableInfo(rawTable: "")
    @State private var movingTableNum: TableInfo = TableInfo(rawTable: "")
    
    @State private var errorAlert: Bool = false
    @State private var itemsPresentAlert: Bool = false
    @State private var takenAlert: Bool = false
    
    @State private var tempMoveTable: String? = nil
    
    var body: some View {
        ZStack{
            GeometryReader { geometry in
                let columns = 4
                let spacing: CGFloat = 8
                let totalSpacing = spacing * CGFloat(columns - 1)
                let itemSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
                
                VStack(alignment: .trailing) {
                    HStack(alignment: .bottom){
                        if(backendManager.appState == .movingTable) {
                            Text("Verplaats naar")
                                .font(.caption)
                        }
                        
                        ZStack {
                            Text(backendManager.appState == .movingTable ? movingTableNum.rawTable : tableNum.rawTable)
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
                                    if(backendManager.appState == .movingTable){
                                        print("Moving table start")
                                        await backendManager.startTable(next: .movingTable, tableInfo: movingTableNum) {
                                            Task {
                                                await backendManager.moveTable(newTable: movingTableNum.formatTable)
                                            }
                                        }
                                    }else {
                                        await backendManager.startTable(next: .tableOpen, tableInfo: tableNum) {
                                            Task {
                                                await backendManager.enterTable()
                                            }
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
                            SelectionButton(text: "Betalen", size: itemSize, action1:  //Normally "Betalen"
                                            { Task { await startPayment() } })
                            SelectionButton(text: "1", size: itemSize, action1: 
                                                {addTableNum("1")})
                            SelectionButton(text: "2", size: itemSize, action1: 
                                                {addTableNum("2")})
                            SelectionButton(text: "3", size: itemSize, action1: 
                                                {addTableNum("3")})
                        }
                        GridRow {
                            SelectionButton(text: (backendManager.appState == .movingTable) ? "" : "Verpl.", size: itemSize, action1: 
                                                {
                                Task {
                                    await backendManager.startTable(next: .movingTable, tableInfo: tableNum) {
                                        tableNum.rawTable = ""
                                        backendManager.appState = .movingTable
                                    }
                                    
                                }
                            })
                            SelectionButton(text: "0", size: itemSize, action1: 
                                                {addTableNum("0")})
                            SelectionButton(text: ".", size: itemSize, action1: 
                                                {addTableNum(".")})
                            SelectionButton(text: "CL", size: itemSize, action1: 
                                                {tableNum.rawTable = ""; movingTableNum.rawTable = ""})
                        }
                        Spacer()
                        HStack{
                            SelectionButton(text: "Annuleren", width: geometry.size.width/3-6, height: geometry.size.width/4-6)
                            {
                                if backendManager.appState == .selection {
                                    backendManager.activeUser = nil
                                    backendManager.appState = .login
                                }else {
                                    backendManager.reset()
                                }
                            }
                            SelectionButton(text: "", width: geometry.size.width/3-6, height: geometry.size.width/4-6)
                            SelectionButton(text: "", width: geometry.size.width/3-6, height: geometry.size.width/4-6)
                        }
                    }
                }
            }
        }
    }
    
    
    func addTableNum(_ symbol: String) {
        let targetTable = backendManager.appState == .movingTable ? movingTableNum : tableNum
        
        if targetTable.rawTable.contains(".") {
            if symbol == "." { return } // Already a dot in the string
            if targetTable.rawTable.firstIndex(of: ".").map({ $0 != targetTable.rawTable.index(before: targetTable.rawTable.endIndex) }) ?? true { return } // Only one character after dot
        } else if targetTable.rawTable.count > 3 && symbol != "." { // Only 4 symbols before dot
            return
        } else if symbol == "." && targetTable.rawTable.count == 0 { // Can't start with dot
            return
        }
        
        if backendManager.appState == .movingTable {
            movingTableNum.rawTable += symbol
        } else {
            tableNum.rawTable += symbol
        }
    }
        
    func startPayment() async {
        await backendManager.startTable(next: .payment, tableInfo: tableNum){
            Task {
                print("Entering Payment")
                _ = await backendManager.startPayment()
            }
        }
    }
}


