//
//  SplitTableView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 3/5/25.
//


import SwiftUI
import Combine


struct SplitTableView: View {
    @ObservedObject var session: SessionManager
    var nextState: SplitActions
    var table: TableInfo
    
    @State private var showAlert: Bool = false

    private let columns: Int = 8
    private let spacing: CGFloat = 1

    private func itemSize(for width: CGFloat) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1)
        return (width - totalSpacing) / CGFloat(columns)
    }

    private func tableRow(subTable: SubTableInfo, itemWidth: CGFloat) -> some View {
        HStack {
            Text(formatTableNum(subTable.table))
                .frame(width: itemWidth, alignment: .leading)
            if subTable.free {
                Text("Free")
            } else {
                Text(subTable.balance)
                Text(subTable.time)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            Task{
                let lastInt = subTable.table.last.flatMap { Int(String($0)) } ?? 0

                var newTable = table
                newTable.setSubTable(lastInt)
                
                session.continueSplitTable(nextTable: newTable, nextState: self.nextState)
                    
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
                    ForEach(session.currentSubTables) { subTable in
                        tableRow(subTable: subTable, itemWidth: itemWidth)
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
                        session.resetState()
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

