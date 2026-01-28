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
    var unk2: Int
    var rang: Int
    var followPrevious: Bool
    var unk3: Bool
    var unk4: Int

    init(plu: Int, name: String, page: Int, price: Double, unk1: Bool, unk2: Int, rang: Int, followPrevious: Bool, unk3: Bool, unk4: Int) {
        self.plu = plu
        self.name = name
        self.page = page
        self.price = price
        self.unk1 = unk1
        self.unk2 = unk2
        self.rang = rang
        self.followPrevious = followPrevious
        self.unk3 = unk3
        self.unk4 = unk4
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
}

struct SubTable: Hashable, Identifiable {
    var id = UUID()
    var table: String
    var balance: String
    var time: String
    var free: Bool
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
    
    var formatTable: String {
        return String(format: "%d%d", table, subTable)
    }
}


