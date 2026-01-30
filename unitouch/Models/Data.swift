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

    init(items: [UnitouchProduct] = [], categories: [UnitouchCategory] = []) {
        self.timestamp = UUID().uuidString
        self.items = items
        self.categories = categories
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
    var lookup: Int
    var rang: Int
    var followPrevious: Bool
    var unk2: Bool
    var unk3: Int

    init(plu: Int, name: String, page: Int, price: Double, unk1: Bool, lookup: Int, rang: Int, followPrevious: Bool, unk32: Bool, unk3: Int) {
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
            let plu = Int(parts[0])
        else {
            return nil
        }
        
        self.plu = plu
        self.name = String(parts[1])
        self.page = Int(parts[2]) ?? -1
        self.price = Double(parts[3]) ?? -1.1
        self.unk1 = (parts[4] == "T")
        self.lookup = Int(parts[5]) ?? 0
        self.rang = Int(parts[6]) ?? -1
        self.followPrevious = (parts[7] == "T")
        self.unk2 = (parts[8] == "T")
        self.unk3 = Int(parts[9]) ?? -1
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
    var listPlace: Int = 0
    
    var output: String {
        return "\(self.id)"
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
        self.listPlace = listPlace
    }
    
    init?(raw: String) {
        let parts = raw.components(separatedBy: "\t")
        
        guard
            parts.count >= 10,
            parts[6].contains("."),
            let user = Int(parts[0]),
            let plu = Int(parts[1])
        else {
            return nil
        }
        
        self.user = user
        self.plu = plu
        self.name = parts[2]
        self.quantity = Int(parts[3]) ?? -1
        self.rang = Int(parts[4]) ?? -1
        self.unk1 = "F"
        self.price = Int(parts[6]) ?? -1 // TODO: Fix
        self.comment = parts[7]=="T" ? true : false
        self.listPlace = Int(parts[10]) ?? -1
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
            parts.count == 2,
            let table = Int(parts[0])
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


