//
//  RestaurantStore.swift
//  unitouch
//
//  Created by Tijn Giesberts on 18/08/2026.
//


import Foundation
import Combine

@MainActor
class RestaurantStore: ObservableObject {
    @Published var backendData: Components.Schemas.SyncData? = nil
    
    var items: [Components.Schemas.Item] { backendData?.items ?? [] }
    var users: [Components.Schemas.User] { backendData?.users ?? [] }
    var tables: [Components.Schemas.RestaurantTable] { backendData?.restaurant_tables ?? [] }
    var categories: [Components.Schemas.Category] { backendData?.categories ?? [] }
    var menus: [Components.Schemas.Menu] { backendData?.menus ?? [] }
    var lookups: [Components.Schemas.Lookup] { backendData?.lookups ?? [] }
    
    // Keeps the exact same logic you had in SessionManager
    func items(forCategory categoryId: String) -> [Components.Schemas.Item] {
        return items.compactMap { item in
            guard let matchingCategory = item.categories.first(where: { $0.category_id == categoryId }) else {
                return nil
            }
            var scopedItem = item
            scopedItem.categories = [matchingCategory]
            return scopedItem
        }
        .sorted { first, second in
            let firstOrder = first.categories.first?.sort_order ?? 0
            let secondOrder = second.categories.first?.sort_order ?? 0
            
            if firstOrder == secondOrder { return first.name < second.name }
            return firstOrder < secondOrder
        }
    }
}