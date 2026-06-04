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

struct BackendData: Codable {
    var timestamp: String
    var items: [UnitouchProduct] = []
    var categories: [UnitouchCategory] = []
    var users: [UnitouchUser] = []
    var lookups: [UnitouchLookup] = []
    var backgrounds: [UnitouchBackground] = []
    var tables: [UnitouchTable] = []
    var tableColors: [UnitouchTableColor] = []

    init() {
        self.timestamp = UUID().uuidString
    }
    
    mutating func reset(_ timestamp: String) {
        self.timestamp = timestamp
        self.items.removeAll()
        self.categories.removeAll()
        self.users.removeAll()
        self.lookups.removeAll()
        self.backgrounds.removeAll()
        self.tables.removeAll()
        self.tableColors.removeAll()
    }
}

struct UnitouchProduct: Codable, Hashable {
    var plu: Int
    var name: String
    var page: Int
    var price: Double
    var unk1: Bool
    var lookup: Int = 0
    var rang: Int
    var followPrevious: Bool
    var unk2: Bool
    var unk3: Int
    var color: Int

    init(plu: Int, name: String, page: Int, price: Double, unk1: Bool, lookup: Int, rang: Int, followPrevious: Bool, unk2: Bool, unk3: Int, color: Int) {
        self.plu = plu
        self.name = name
        self.page = page
        self.price = price
        self.unk1 = unk1
        self.lookup = lookup
        self.rang = rang
        self.followPrevious = followPrevious
        self.unk2 = unk2
        self.unk3 = unk3
        self.color = color
    }
    
    init?(raw: String){
        let parts = raw.split(separator: "\t")
        
        guard
            parts.count >= 10,
            let plu = Int(parts[0]),
            let page = Int(parts[2]),
            let price = Double(parts[3]),
            let lookup = Int(parts[5]),
            let rang = Int(parts[6]),
            let unk3 = Int(parts[9])
        else {
            print("Item not added \(parts[2]) \(parts[1]))")
            return nil
        }
        let color = Int(parts.last ?? "0") ?? 0
        
        self.plu = plu
        self.name = String(parts[1])
        self.page = page
        self.price = price
        self.unk1 = (parts[4] == "T")
        self.lookup = lookup
        self.rang = rang
        self.followPrevious = (parts[7] == "T")
        self.unk2 = (parts[8] == "T")
        self.unk3 = unk3
        self.color = color
    }
}

struct UnitouchCategory: Codable, Hashable {
    var id: Int
    var name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    init?(raw: String) {
        let parts = raw.split(separator: "\t")
        
        guard
            parts.count == 2,
            let id = Int(parts[0])
        else {
            return nil
        }
        
        self.id = id
        self.name = String(parts[1])
    }
}

struct UnitouchUser: Codable, Hashable {
    var id: Int
    var name: String
    var password: String
    
    init(id: Int, name: String, password: String) {
        self.id = id
        self.name = name
        self.password = password
    }
    
    init?(raw: String) {
        let parts = raw.split(separator: "\t")
        
        guard
            parts.count == 3,
            let id = Int(parts[0])
        else {
            return nil
        }
        
        self.id = id
        self.name = String(parts[1])
        self.password = String(parts[2])
        
    }
}

struct UnitouchLookup: Codable {
    var id: Int
    var items: [Int]
    
    init(id: Int, items: [Int]) {
        self.id = id
        self.items = items
    }
    
    init?(raw: String){
        let parts = raw.split(separator: "\t")
        
        guard
            parts.count >= 2,
            let id = Int(parts[0]),
            let child = Int(parts[1])
        else { return nil }
        
        self.id = id
        self.items = [child]
    }
}

struct UnitouchBackground: Codable {
    var id: Int
    var imageData: Data
    
    init(id: Int, imageData: Data) {
        self.id = id
        self.imageData = imageData
    }
    
    var image: UIImage {
        get { UIImage(data: imageData) ?? UIImage() }
        set { imageData = newValue.pngData() ?? Data() }
    }
}

struct UnitouchTable: Codable, Hashable, Identifiable {
    var id = UUID()
    var BTNfrmCnt: Int
    var BTNcllCnt: Int
    var BTNlabel: String
    var BTNx: Int
    var BTNy: Int
    var BTNw: Int
    var BTNh: Int
    var BTNr: Int
    var BTNaccNum: Int
    
    init(BTNfrmCnt: Int, BTNcllCnt: Int, BTNlabel: String, BTNx: Int, BTNy: Int, BTNw: Int, BTNh: Int, BTNr: Int, BTNaccNum: Int) {
        self.BTNfrmCnt = BTNfrmCnt          // On what screen it appears
        self.BTNcllCnt = BTNcllCnt          // Local screen id
        self.BTNlabel = BTNlabel            // Label of table
        self.BTNx = BTNx                    // X position on screen
        self.BTNy = BTNy                    // Y position on screen
        self.BTNw = BTNw                    // Width of table button
        self.BTNh = BTNh                    // Height of table button
        self.BTNr = BTNr                    // ???? No fucking clue (seems to be font size or something)
        self.BTNaccNum = BTNaccNum          // Actual table number
    }
    
    init?(raw: String){
        let parts = raw.split(separator: "\t")
        
        guard
            parts.count >= 9,
            let BTNfrmCnt = Int(parts[0]),
            let BTNcllCnt = Int(parts[1]),
            let BTNx = Int(parts[3]),
            let BTNy = Int(parts[4]),
            let BTNw = Int(parts[5]),
            let BTNh = Int(parts[6]),
            let BTNr = Int(parts[7]),
            let BTNaccNum = Int(parts[8])
        else {
            return nil
        }
        
        self.BTNfrmCnt = BTNfrmCnt
        self.BTNcllCnt = BTNcllCnt
        self.BTNlabel = String(parts[2])
        self.BTNx = BTNx
        self.BTNy = BTNy
        self.BTNw = BTNw
        self.BTNh = BTNh
        self.BTNr = BTNr
        self.BTNaccNum = BTNaccNum
    }
}

struct UnitouchTableColor: Codable {
    var id = UUID()
    var BTNStatus: Int
    var BTNFill: Int
    var BTNText: Int
    
    init(id: UUID = UUID(), BTNStatus: Int, BTNFill: Int, BTNText: Int) {
        self.id = id
        self.BTNStatus = BTNStatus
        self.BTNFill = BTNFill
        self.BTNText = BTNText
    }
}

struct NewItem: Hashable, Identifiable {
    var id = UUID()
    var user: Int
    var plu: Int
    var name: String
    var quantity: Int
    var rang: Int
    var unk1: String
    var price: Int
    var comment: Bool
    var delete: String = ""
    var splitMove: Int = 0
    var listPlace: Int = 0
    
    var outputNew: String {
        return "\(user)\t\(plu)\t\(name)\t\(quantity)\t\(rang)\t\(unk1)\t\(price)\t\(comment ? "T" : "F")\t\t\(splitMove)\t\(listPlace)\t0\t0\t0\t0\t0\tF\n"
    }
    
    var outputDelete: String {
        return "\(user)\t\(plu)\t\(name)\t\(quantity)\t\(rang)\t\(unk1)\t\(price)\t\(comment ? "T" : "F")\tX\t\(splitMove)\t\(listPlace)\t0\t0\t0\t0\t0\tF\n"
    }
    
    var outputSplitMove: String {
        return "\(user)\t\(plu)\t\(name)\t\(quantity)\t\(rang)\t\(unk1)\t\(price)\t\(comment ? "T" : "F")\t*\t\(splitMove)\t\(listPlace)\t0\n"
    }
    
    init(
        id: UUID = UUID(),
        user: Int,
        plu: Int,
        name: String,
        quantity: Int,
        rang: Int,
        unk1: String = "F",
        price: Int,
        comment: Bool,
        splitMove: Int = 0,
        listPlace: Int = 0
    ) {
        self.id = id
        self.user = user
        self.plu = plu
        self.name = name
        self.quantity = quantity
        self.rang = rang
        self.unk1 = unk1
        self.price = price
        self.comment = comment
        self.splitMove = splitMove
        self.listPlace = listPlace
    }

    init?(raw: String) {
        let parts = raw.components(separatedBy: "\t")

        guard
            parts.count >= 10,
            let user = Int(parts[0]),
            let plu = Int(parts[1]),
            let splitMove = Int(parts[9]),
            let listPlace = Int(parts[10])
        else { return nil }

        let priceStr = parts[6]
        let priceCents: Int?
        if priceStr.contains(".") {
            if let priceDouble = Double(priceStr) {
                priceCents = Int(round(priceDouble * 100))
            } else {
                return nil
            }
        } else if let cents = Int(priceStr) {
            priceCents = cents
        } else {
            return nil
        }

        guard let price = priceCents else { return nil }

        self.user = user
        self.plu = plu
        self.name = parts[2]
        self.quantity = Int(parts[3]) ?? -1
        self.rang = Int(parts[4]) ?? -1
        self.unk1 = "F"
        self.price = price
        self.comment = parts[7]=="T" ? true : false
        self.splitMove = splitMove
        self.listPlace = listPlace
    }
}

struct SubTableInfo: Hashable, Identifiable {
    var id = UUID()
    var table: String
    var balance: String
    var time: String
    var free: Bool
    
    init?(raw: String){
        let parts = raw.components(separatedBy: "\t")
        guard
            parts.count >= 6
        else {
            return nil
        }
        
        self.table = parts[0]
        self.balance = parts[1]
        self.time = parts[2]
        self.free = (parts[5] == "Free")
    }
}

struct TableInfo: Equatable {
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

struct OpenTable: Identifiable {
    var id = UUID()
    var tableInfo: TableInfo
    var balance: Double
    var time: String
    var comment: String
    var status: Int
    
    init(tableInfo: TableInfo, balance: Double, time: String, comment: String, status: Int) {
        self.id = UUID()
        self.tableInfo = tableInfo
        self.balance = balance
        self.time = time
        self.comment = comment
        self.status = status
    }
    
    init?(raw: String) {
        let parts = raw.components(separatedBy: "\t")
        print(parts)
        
        guard
            parts.count >= 8,
            let tableInfo = TableInfo(flatTable: String(parts[0])),
            let balance = Double(parts[1]),
            let status = Int(parts[7])
        else {
            return nil
        }
        
        self.tableInfo = tableInfo
        self.balance = balance
        self.time = parts[2]
        self.comment = parts[5]
        self.status = status
        
    }
}


