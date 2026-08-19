//
//  SessionManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 26/01/2026.
//

import Foundation
import Combine
import SwiftData
import UIKit

import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes

@MainActor
class SessionManager: ObservableObject {
    // State
    @Published var state: AppState = .disconnected
    @Published var preservedState: AppState? = nil
    @Published var activeError: UnitouchError? = nil
    
    @Published var backendData: Components.Schemas.SyncData? = nil
    var items: [Components.Schemas.Item] {  backendData?.items ?? [] }
    var users: [Components.Schemas.User] { backendData?.users ?? [] }
    var tables: [Components.Schemas.RestaurantTable] { backendData?.restaurant_tables ?? [] }
    var categories: [Components.Schemas.Category] { backendData?.categories ?? [] }
    var menus: [Components.Schemas.Menu] { backendData?.menus ?? [] }
    var lookups: [Components.Schemas.Lookup] { backendData?.lookups ?? [] }
    
    func items(forCategory categoryId: String) -> [Components.Schemas.Item] {
            return items.compactMap { item in
                // 1. Find the specific category linkage for this categoryId
                guard let matchingCategory = item.categories.first(where: { $0.category_id == categoryId }) else {
                    return nil
                }
                
                // 2. Create a modified copy of the item containing only this category
                var scopedItem = item
                scopedItem.categories = [matchingCategory]
                return scopedItem
            }
            // 3. Sort items by the category's sort_order (and fallback to name)
            .sorted { first, second in
                let firstOrder = first.categories.first?.sort_order ?? 0
                let secondOrder = second.categories.first?.sort_order ?? 0
                
                if firstOrder == secondOrder {
                    return first.name < second.name
                }
                return firstOrder < secondOrder
            }
        }
    
    // Persistent Memory
    var currentUser: Components.Schemas.User? // Using generated User schema
    var currentTable: ActiveTable?
    var currentSubTableId: Int = 0
    
    @Published var currentTableItems: [Components.Schemas.OrderItem] = []
    @Published var newItems: [Components.Schemas.OrderItem] = []
    @Published var deletedItems: [String] = [] // Just store UUIDs for deletion
    
    @Published var openTables: [ActiveTable] = []
    @Published var currentSubTables: [Components.Schemas.SubTable] = []
    @Published var blockedItems: [Components.Schemas.ItemLock] = []
    
    @Published var requestMoveConformation: Components.Schemas.RestaurantTable? = nil
    
    // 1. Initialize the OpenAPI Client
    lazy var client: Client = {
        Client(
            serverURL: URL(string: "http://192.168.1.100:8080/api")!,
            transport: URLSessionTransport(),
            middlewares: [
                AuthenticationMiddleware { [weak self] in
                    self?.currentUser?.id
                }
            ]
        )
    }()
    
    init() {
        self.state = .userSelection
    }
    
    // MARK: - Headers Helper
    // Generates the required X-User-ID header for table endpoints
    private var authHeader: HTTPField {
        guard let userId = currentUser?.id else {
            fatalError("Attempted to make authenticated call without a user")
        }
        return HTTPField(name: .init("X-User-ID")!, value: userId)
    }

    // MARK: - Data Syncing
    func getData() async {
        self.state = .loading("Syncing Data...")
        
        do {
            let response = try await client.syncData()
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let syncData):
                    self.backendData = syncData
                    self.state = .main
                }
            case .internalServerError(_):
                self.activeError = .dataSyncFailed(details: "Server error during sync")
            case .undocumented(let statusCode, _):
                self.activeError = .dataSyncFailed(details: "Unknown status: \(statusCode)")
            }
        } catch {
            self.activeError = .networkError(details: error.localizedDescription)
            self.state = .disconnected
        }
    }
    
    // MARK: - Table Management
    func getOpenTables() async {
        do {
            let response = try await client.getTables()
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let tables):
                    self.openTables = [] // TODO: - FIX - tables
                }
            default:
                print("Failed to fetch open tables")
            }
        } catch {
            self.activeError = .networkError(details: error.localizedDescription)
        }
    }
    
    func searchTables() async {
        let aggregatedItems = self.newItems.reduce(into: [String: Int]()) { result, item in
            result[item.item_id, default: 0] += item.quantity
        }

        let searchPayload = aggregatedItems.map { itemId, totalQuantity in
            Components.Schemas.TableSearchItem(
                item_id: itemId,
                quantity: totalQuantity
            )
        }
        
        do {
            // 2. Make the API call
            let response = try await client.searchTables(
                body: .json(searchPayload)
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let searchResults):
                    self.openTables = searchResults.compactMap { result in
                        guard let physicalTable = self.tables.first(where: { $0.id == result.id }) else {
                            return nil
                        }
                        
                        return ActiveTable(
                            physicalTable: physicalTable,
                            subTableIndex: result.sub_table
                        )
                    }
                    
                }
            default:
                self.activeError = .invalidServerResponse(action: "Tafel Zoeken", details: "Onverwachte status")
            }
        } catch {
            self.activeError = .networkError(details: error.localizedDescription)
        }
    }
    
    func enterTable(tableId: String, subTable: Int) async {
        self.state = .loading("Opening Table...")
        
        do {
            let response = try await client.getTableOrder(
                path: .init(id: tableId, sub_table: subTable),
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let orderData):
                    self.currentTableItems = orderData.items
                    self.currentSubTableId = subTable
                    self.state = .order
                }
            case .forbidden(_):
                self.activeError = .tableLocked
                self.resetState()
            default:
                self.activeError = .openTableFailed(details: "Server Error")
            }
        } catch {
            self.activeError = .networkError(details: error.localizedDescription)
        }
    }
    
    func finishTable(closeTable: Bool = true) async {
        guard let tableId = currentTable?.physicalTable.id else { return }
        
        // If no changes, just unlock the table
        if newItems.isEmpty && deletedItems.isEmpty {
            if closeTable { try? await unlockTable(tableId: tableId, subTable: currentSubTableId) }
            return
        }
        
        do {
            // Build the payload using the generated models
            let payload = Components.Schemas.TableUpdateRequest(
                add: newItems,
                remove: deletedItems
            )
            
            let response = try await client.updateTable(
                path: .init(id: tableId, sub_table: currentSubTableId),
                body: .json(payload)
            )
            
            switch response {
            case .ok(_):
                if closeTable {
                    try? await unlockTable(tableId: tableId, subTable: currentSubTableId)
                    self.resetState()
                } else {
                    self.newItems.removeAll()
                    self.deletedItems.removeAll()
                    await enterTable(tableId: tableId, subTable: currentSubTableId) // Refresh
                }
            case .forbidden(_):
                self.activeError = .tableLocked
            default:
                self.activeError = .invalidServerResponse(action: "Saving Order", details: "Failed")
            }
        } catch {
            self.activeError = .networkError(details: error.localizedDescription)
        }
    }
    
    private func unlockTable(tableId: String, subTable: Int) async throws {
        _ = try await client.unlockTable(
            path: .init(id: tableId, sub_table: subTable),
        )
        self.resetState()
    }
    
    // MARK: - Payments
    func startPayment() async {
        print("fuck")
    }
    
    func finishPayment(methodName: String, tipAmount: Double) async {
        guard let tableId = currentTable?.physicalTable.id else { return }
        
        do {
            // Setup the generated payload[cite: 2]
            let payload = Components.Schemas.PaymentFinalizeRequest(
                method: methodName,
                tip_amount: tipAmount
            )
            
            let response = try await client.finalizePayment(
                path: .init(id: tableId, sub_table: currentSubTableId),
                body: .json(payload)
            )
            
            switch response {
            case .ok(_):
                self.resetState() // Order is closed, return to main screen!
            case .forbidden(_):
                self.activeError = .tableLocked
            case .badRequest(_):
                self.activeError = .paymentCompletionFailed(details: "Invalid payment data")
            default:
                self.activeError = .paymentCompletionFailed(details: "Server Error")
            }
        } catch {
            self.activeError = .networkError(details: error.localizedDescription)
        }
    }

    func resetState() {
        self.state = .main
        self.currentTable = nil
        self.currentSubTableId = 0
        self.currentTableItems.removeAll()
        self.newItems.removeAll()
        self.deletedItems.removeAll()
    }
//}
//
//
//extension SessionManager {
    
    func tableStrToActiveTable(tableStr: String) -> ActiveTable? {
        let pattern = #"^(?!\.)(\d{0,4})(?:\.(\d)?)?$"#
        do {
            let regex = try Regex(pattern)
            
            if let match = tableStr.firstMatch(of: regex) {
                guard let tableNumber = match[1].value as? Int else { return nil }
                let subTable = match[2].value as? Int ?? 0
                
                guard
                    let data = self.backendData,
                    let tables = data.restaurant_tables,
                    let table = tables.first(where: { $0.number == tableNumber })
                else { return nil }
                
                return ActiveTable(physicalTable: table, subTableIndex: subTable)
                
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
}
