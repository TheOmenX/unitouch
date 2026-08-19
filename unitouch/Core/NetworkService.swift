//
//  NetworkService.swift
//  unitouch
//  Created by Tijn Giesberts on 18/08/2026.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes

// Custom DateTranscoder compatible with Swift 6 Strict Concurrency
struct FlexibleISO8601DateTranscoder: DateTranscoder, Sendable {
    func encode(_ date: Date) throws -> String {
        date.formatted(
            .iso8601
                .year().month().day()
                .time(includingFractionalSeconds: true)
                .timeZone(separator: .omitted)
        )
    }
    
    func decode(_ dateString: String) throws -> Date {
        // 1. Try parsing with fractional seconds (e.g. .123456Z or .123Z)
        if let date = try? Date(
            dateString,
            strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true)
        ) {
            return date
        }
        
        // 2. Fallback to standard ISO8601 without fractional seconds
        if let date = try? Date(
            dateString,
            strategy: .iso8601.year().month().day().time(includingFractionalSeconds: false)
        ) {
            return date
        }
        
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Expected ISO8601 date string, but received: \(dateString)"
            )
        )
    }
}

// A Singleton service because we only ever need one network client
class NetworkService {
    static let shared = NetworkService()
    
    // The AppRouter updates this when a user logs in
    var currentUserId: String?
    
    // Lazy Client initialized with custom configuration for date transcoding
    lazy var client: Client = {
        let configuration = Configuration(
            dateTranscoder: FlexibleISO8601DateTranscoder()
        )
        
        return Client(
            serverURL: URL(string: "http://192.168.101.240:8080/api")!,
            configuration: configuration,
            transport: URLSessionTransport(),
            middlewares: [
                AuthenticationMiddleware { [weak self] in
                    self?.currentUserId
                }
            ]
        )
    }()
    
    private init() {}
    
    // MARK: - API Calls
    
    func syncData() async throws -> Components.Schemas.SyncData {
        let response = try await client.syncData()
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let syncData): return syncData
            }
        case .internalServerError(_):
            throw UnitouchError.dataSyncFailed(details: "Server error during sync")
        case .undocumented(let statusCode, _):
            throw UnitouchError.dataSyncFailed(details: "Unknown status: \(statusCode)")
        }
    }
    
    func getOpenTables() async throws -> [Components.Schemas.TableSearchResult] {
        let response = try await client.getTables()
        
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let tables):
                return tables
            }
        case .internalServerError(_):
            throw UnitouchError.networkError(details: "Serverfout bij het ophalen van open tafels.")
        default:
            throw UnitouchError.invalidServerResponse(action: "Open Tafels Ophalen", details: "Onverwachte status ontvangen.")
        }
    }
    
    func getTableOrder(tableId: String, subTable: Int) async throws -> Components.Schemas.GetTableOrderResponse {
        let response = try await client.getTableOrder(path: .init(id: tableId, sub_table: subTable))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let orderData): return orderData
            }
        case .forbidden(_):
            throw UnitouchError.tableLocked
        default:
            throw UnitouchError.openTableFailed(details: "Server Error")
        }
    }
    
    func updateTable(tableId: String, subTable: Int, payload: Components.Schemas.TableUpdateRequest) async throws {
        let response = try await client.updateTable(path: .init(id: tableId, sub_table: subTable), body: .json(payload))
        switch response {
        case .ok(_): return
        case .forbidden(_): throw UnitouchError.tableLocked
        default: throw UnitouchError.invalidServerResponse(action: "Saving Order", details: "Failed")
        }
    }
    
    func setGuestCount(tableID: String, subTable: Int, payload: Components.Schemas.SetGuestCountRequest) async throws {
        let response = try await client.setGuestCount(path: .init(id: tableID, sub_table: subTable), body: .json(payload))
        print(response)
        switch response {
        case .ok(_): return
        case .forbidden(_): throw UnitouchError.tableLocked
        default: throw UnitouchError.invalidServerResponse(action: "Setting Guest Count", details: "Failed")
        }
    }
    
    func unlockTable(tableId: String, subTable: Int) async throws {
        _ = try await client.unlockTable(path: .init(id: tableId, sub_table: subTable))
    }
    
    func finalizePayment(tableId: String, subTable: Int, payload: Components.Schemas.PaymentFinalizeRequest) async throws {
        let response = try await client.finalizePayment(path: .init(id: tableId, sub_table: subTable), body: .json(payload))
        switch response {
        case .ok(_): return
        case .forbidden(_): throw UnitouchError.tableLocked
        case .badRequest(_): throw UnitouchError.paymentCompletionFailed(details: "Invalid payment data")
        default: throw UnitouchError.paymentCompletionFailed(details: "Server Error")
        }
    }
}
