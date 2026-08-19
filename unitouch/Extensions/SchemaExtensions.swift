//
//  SchemaExtensions.swift
//  unitouch
//
//  Created by Tijn Giesberts on 17/08/2026.
//

import Foundation

// MARK: - Identifiable Conformance for OpenAPI Schemas
extension Components.Schemas.Lookup: Identifiable {}
extension Components.Schemas.Item: Identifiable {}
extension Components.Schemas.Category: Identifiable {}
extension Components.Schemas.User: Identifiable {}
extension Components.Schemas.RestaurantTable: Identifiable {}
extension Components.Schemas.Menu: Identifiable {}
extension Components.Schemas.MenuStep: Identifiable {}
extension Components.Schemas.OrderItem: Identifiable {}
extension Components.Schemas.TableSearchResult: Identifiable {}


// MARK: - Array of ItemLink Helpers (Lookups & Menus)

@MainActor
extension Array where Element == Components.Schemas.ItemLink {
    /// Resolves an array of ItemLink references into fully hydrated, sorted Item objects.
    func resolvedItems(using store: RestaurantStore) -> [Components.Schemas.Item] {
        self.sorted { $0.sort_order < $1.sort_order }
            .compactMap { link in
                store.items.first(where: { $0.id == link.item_id })
            }
    }
}

@MainActor
extension Array where Element == Components.Schemas.RestaurantTable {
    func findTable(using store: RestaurantStore, tableNum: Int) -> Components.Schemas.RestaurantTable? {
        store.tables.first { $0.number == tableNum }
    }
}
        



// MARK: - Item Hydration Extensions

@MainActor
extension Components.Schemas.Item {
    /// Resolves the optional Lookup attached to this item.
    func resolvedLookup(in store: RestaurantStore) -> Components.Schemas.Lookup? {
        guard let lookupId = self.lookup_id else { return nil }
        return store.lookups.first(where: { $0.id == lookupId })
    }

    /// Resolves the optional Menu attached to this item.
    func resolvedMenu(in store: RestaurantStore) -> Components.Schemas.Menu? {
        guard let menuId = self.menu_id else { return nil }
        return store.menus.first(where: { $0.id == menuId })
    }

    /// Resolves all full Category objects this item belongs to.
     func resolvedCategories(in store: RestaurantStore) -> [Components.Schemas.Category] {
        let categoryIDs = Set(self.categories.map { $0.category_id })
        return store.categories
            .filter { categoryIDs.contains($0.id) }
            .sorted { $0.sort_order < $1.sort_order }
    }

    /// Helper to get the category-specific color for a given category context.
    func color(for categoryId: String) -> String {
        self.categories.first(where: { $0.category_id == categoryId })?.color ?? "#FFFFFF"
    }
}

// MARK: - Category Hydration Extensions
@MainActor
extension Components.Schemas.Category {
    /// Returns all items assigned to this category, ordered by their category-specific sort_order.
    func resolvedItems(in store: RestaurantStore) -> [Components.Schemas.Item] {
        store.items(forCategory: self.id)
    }
}

// MARK: - Lookup & Menu Convenience
@MainActor
extension Components.Schemas.Lookup {
    func resolvedItems(using store: RestaurantStore) -> [Components.Schemas.Item] {
        self.items.resolvedItems(using: store)
    }
}

@MainActor
extension Components.Schemas.MenuStep {
    func resolvedItems(using store: RestaurantStore) -> [Components.Schemas.Item] {
        self.items.resolvedItems(using: store)
    }
}

@MainActor
extension Components.Schemas.TableSearchResult {
    func resolvedTable(in store: RestaurantStore) -> Components.Schemas.RestaurantTable? {
        store.tables.first(where: { $0.id == self.id })
    }
}

@MainActor
extension Components.Schemas.RestaurantTable {
    func displayLabel(_ subTableIndex: Int) -> String {
        return self.label ?? "\(self.number).\(subTableIndex)"
    }
}
