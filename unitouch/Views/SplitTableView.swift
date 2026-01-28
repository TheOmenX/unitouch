//
//  SplitTableView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 3/5/25.
//


import SwiftUI

struct SplitTableView: View {
    @State var backendManager = BackendManager.shared
    @State private var showAlert: Bool = false

    private let columns: Int = 8
    private let spacing: CGFloat = 1

    private func itemSize(for width: CGFloat) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1)
        return (width - totalSpacing) / CGFloat(columns)
    }

    private func tableRow(table: SubTable, itemWidth: CGFloat) -> some View {
        HStack {
            Text(formatTableNum(table.table))
                .frame(width: itemWidth, alignment: .leading)
            if table.free {
                Text("Free")
            } else {
                Text(table.balance)
                Text(table.time)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            Task{
                let lastCharAsString = String(table.table.last ?? "0")
                
                if case let .splitTable(table, forTable) = backendManager.appState {
                    if forTable != .movingTable {
                        backendManager.activeTable = table
                        backendManager.activeSubTable = Int(lastCharAsString) ?? 0
                    }
                    
                    
                    switch forTable {
                    case .tableOpen:
                        await backendManager.enterTable()
                    case .movingTable:
                        if(backendManager.activeSubTable == nil) {
                            backendManager.activeTable = table
                            backendManager.activeSubTable = Int(lastCharAsString) ?? 0
                            backendManager.appState = .movingTable
                        }else {
                            await backendManager.moveTable(newTable: "\(table)\(Int(lastCharAsString) ?? 0)")
                            backendManager.appState = .selection
                        }
                    case .payment:
                        backendManager.activeSubTable = Int(lastCharAsString) ?? 0
                        
                    default:
                        break
                    }
                }
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let itemWidth = itemSize(for: geometry.size.width)
            VStack {
                Text("Sub tafels")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    
                List {
                    // Using id parameter is not needed as SubTable conforms to Identifiable
                    ForEach(backendManager.splitTables) { table in
                        tableRow(table: table, itemWidth: itemWidth)
                    }
                }
                .listStyle(.plain)
                Spacer()
                HStack {
                    SelectionButton(
                        text: "Annuleren",
                        width: geometry.size.width / 3 - 6,
                        height: geometry.size.width / 4 - 6
                    ) {
                        backendManager.activeTable = nil
                    }
                    SelectionButton(
                        text: "",
                        width: geometry.size.width / 3 - 6,
                        height: geometry.size.width / 4 - 6
                    )
                    SelectionButton(
                        text: "",
                        width: geometry.size.width / 3 - 6,
                        height: geometry.size.width / 4 - 6
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Kon tafel niet openen"),
                    message: Text("Er ging iets mis met het openen van de tafel.")
                )
            }
        }
    }

    func formatTableNum(_ input: String) -> String {
        guard input.count >= 2 else { return input }
        let index = input.index(input.endIndex, offsetBy: -1)
        let beforeLast = input[..<index]
        let last = input[index...]
        return "\(beforeLast).\(last)"
    }
}

#Preview {
    SplitTableView()
}
