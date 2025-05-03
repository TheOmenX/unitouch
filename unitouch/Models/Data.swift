//
//  NetworkManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import Foundation

struct Item: Hashable {
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
}

struct Category: Hashable {
    var id: Int
    var name: String
}

