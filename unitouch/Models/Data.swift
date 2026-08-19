//
//  NetworkManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import Foundation
import SwiftData
import UIKit


@Model
class Payment: Identifiable {
    var id: UUID;
    var time: Date;
    var user: String;
    var table: String;
    var amount: Decimal;
    var tip: Decimal;
    
    init(user: String, table: String, amount: Decimal, tip: Decimal) {
        self.id = UUID()
        self.time = Date()
        self.user = user
        self.table = table
        self.amount = amount
        self.tip = tip
    }
}

struct TableInfo_Old: Equatable {
    var rawTable: String
    
    init(rawTable: String) {
        self.rawTable = rawTable
    }
    
    init?(flatTable: String) {
        guard flatTable.count >= 2 else { return nil }

        let tableRawSubstring = flatTable.dropLast()           // Substring
        let subTableChar = flatTable.last!                     // Character

        guard
            let tableNum = Int(String(tableRawSubstring)),
            let subTableNum = Int(String(subTableChar))
        else {
            return nil
        }

        self.rawTable = "\(tableNum).\(subTableNum)"
    }
    
    var table: Int {
        if rawTable.contains(".") {
            return Int(rawTable.split(separator: ".")[0]) ?? 0
        } else {
            return Int(rawTable) ?? 0
        }
    }
    var subTable: Int {
        if rawTable.contains(".") && rawTable.split(separator: ".").count > 1 {
            return Int(rawTable.split(separator: ".")[1]) ?? 0
        } else {
            return 0
        }
    }
    
    var isSubTableSet: Bool {
        return rawTable.split(separator: ".").count > 1
    }
    
    var formatTableFlat: String {
        return String(format: "%d%d", table, subTable)
    }
    
    var formatTableRaw: String {
        return String(format: "%d.%d", table, subTable)
    }
    
    mutating func setSubTable(_ subTable: Int) {
        self.rawTable = "\(table).\(subTable)"
    }
    
    static func validTable(tableString: String) -> Bool {
        let pattern = #"^\d+(\.\d+)?$"#
        return tableString.range(of: pattern, options: .regularExpression) != nil
    }
    
    static func validTableInput(tableString: String) -> Bool {
        let pattern = #"^\d{,4}((\.\d)?|\.)$"#
        return tableString.range(of: pattern, options: .regularExpression) != nil
    }
    
}

struct ActiveTable: Equatable, Identifiable {
    let id = UUID()
    let physicalTable: Components.Schemas.RestaurantTable
    var subTableIndex: Int
    
    // MARK: - Helpful Computed Properties
    
    /// Formats the table for the UI (e.g., "Table 12" or "Table 12.2")
    var displayLabel: String {
        return physicalTable.label ?? "Tafel \(physicalTable.number).\(subTableIndex)"
    }
    
    /// The string format required if you ever need to match your old "101.1" format
    var rawFormat: String {
        return "\(physicalTable.number).\(subTableIndex)"
    }
    
    // Add Equatable conformance so SwiftUI can watch for state changes
    static func == (lhs: ActiveTable, rhs: ActiveTable) -> Bool {
        return lhs.physicalTable.id == rhs.physicalTable.id &&
               lhs.subTableIndex == rhs.subTableIndex
    }
}

