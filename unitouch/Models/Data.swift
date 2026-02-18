//
//  NetworkManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import Foundation
import SwiftData


@Model
class BackendData {
    @Relationship var timestamp: String;
    @Relationship var items: [UnitouchProduct] = []
    @Relationship var categories: [UnitouchCategory] = []
    @Relationship var users: [UnitouchUser] = []
    @Relationship var lookups: [UnitouchLookup] = []

    init() {
        self.timestamp = UUID().uuidString
    }
    
    func reset(_ timestamp: String) {
        self.timestamp = timestamp
        self.items.removeAll()
        self.categories.removeAll()
        self.users.removeAll()
    }
}

@Model
class UnitouchProduct {
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

    init(plu: Int, name: String, page: Int, price: Double, unk1: Bool, lookup: Int, rang: Int, followPrevious: Bool, unk2: Bool, unk3: Int) {
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
            return nil
        }
        
        self.plu = plu
        self.name = String(parts[1])
        self.page = page
        self.price = price
        self.unk1 = (parts[4] == "T")
        self.lookup = Int(parts[5]) ?? 0
        self.rang = Int(parts[6]) ?? -1
        self.followPrevious = (parts[7] == "T")
        self.unk2 = (parts[8] == "T")
        self.unk3 = unk3
    }
}

@Model
class UnitouchCategory {
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

@Model
class UnitouchUser {
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

@Model
class UnitouchLookup {
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
            if let d = Double(priceStr) {
                priceCents = Int(round(d * 100))
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
        if rawTable.contains(".") {
            return Int(rawTable.split(separator: ".")[1]) ?? 0
        } else {
            return 0
        }
    }
    
    var isSubTableSet: Bool {
        return rawTable.split(separator: ".").count > 1
    }
    
    var formatTableRaw: String {
        return String(format: "%d%d", table, subTable)
    }
    
    var formatTable: String {
        return String(format: "%d.%d", table, subTable)
    }
    
    mutating func setSubTable(_ subTable: Int) {
        self.rawTable = "\(table).\(subTable)"
    }
    
}


