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

// --- APP STATE ENUM ---
enum AppState: Equatable {
    case disconnected
    case loading(String)
    case userSelection                                                  // Screen 1: Pick User
    case pinEntry                                                       // Screen 2: Enter PIN
    case splitSelection(table: TableInfo, nextState: SubTableActions)
    case main                                                           // Screen 3: Main Input
    case splitTable(nextAction: SplitTableActions)                           // Screen 4: Split Table
    case order                                                          // Screen 4: The "Move or Pay" logic
    case payment(balance: Double, bill: String)
}

enum SubTableActions: Equatable {
    case openTable
    case moveTable
    case payTable
    case splitTable
}

enum SplitTableActions: Equatable {
    case move
    case pay
}


@MainActor
class SessionManager: ObservableObject {
    // State
    @Published var state: AppState = .disconnected
    @Published var preservedState: AppState? = nil
    @Published var activeError: UnitouchError? = nil
    
    // Global Data
    var backendData: BackendData = BackendData()
    
    // Persistent Memory
    var currentUser: UnitouchUser?
    var currentTable: TableInfo?
    @Published var currentTableItems: [NewItem] = []
    var currentSubTables: [SubTableInfo] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        TCPClient.shared.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleConnectionChange(status)
            }
            .store(in: &cancellables)
        
        TCPClient.shared.start()
    }
    
    private func handleConnectionChange(_ status: ConnectionStatus) {
        switch status {
        case .connected:
            self.state = .main
            if self.currentUser == nil {
                print("🔄 TCP Connected")
                self.resetState()
                self.state = .userSelection
            } else if let currentTable = self.currentTable, let preservedState = self.preservedState {
                switch preservedState {
                case .order:
                    self.enterTable(table: currentTable)
                case .payment:
                    self.startPayment(table: currentTable)
                default:
                    self.state = .main
                }
            }
            
            self.preservedState = nil
            
        case .disconnected, .failed:
            //print("🔴 TCP Disconnected - current state \(self.state) -- preserved state \(self.preservedState)")
            if self.preservedState == nil { self.preservedState = self.state }
            self.state = .disconnected
            
        case .connecting:
            self.state = .loading("Connecting...")
            // If we have a user and pin, try to auto-login (silent restore)
            if let user = currentUser {
                print("🔄 TCP Connected: Attempting session restore for \(user.name)...")
                self.setUsers(user: user, setState: false)
            }
        }
    }
    
    func verifyData(modelContext: ModelContext, backendData: BackendData) async {
        self.backendData = backendData
        TCPClient.shared.sendCommand("DATAGET TIMESTAMP.txt", type: .download) { response in
            switch response{
            case .content(data: let timestamp):
                if timestamp.trimmingCharacters(in: .whitespacesAndNewlines) != backendData.timestamp.trimmingCharacters(in: .whitespacesAndNewlines) {
                    Task{
                        print("Timestamp mismatch, updating data...")
                        self.backendData.reset(timestamp)
                        await self.getData(modelContext: modelContext)
                    }
                }
            case .error(let error):
                print("Error: \(error)")
            case .success:
                print("Timestamp not recieved")
            }
        }
    }
    
    // MARK: Data Retrieval
    func getData(modelContext: ModelContext) async {
        do {
            // MARK: GET ALL USERS
            TCPClient.shared.sendCommand("DATAGET WAITER.txt", type: .download) { response in
                switch response {
                case .success(code: _, message: _):
                    print("Error: Expeced to recieve data")
                case .content(data: let data):
                    for line in data.split(separator: "\n") {
                        if let newUser = UnitouchUser(raw:String(line)) {
                            self.backendData.users.append(newUser)
                        }
                    }
                case .error(let error):
                    print("Error: \(error)")
                }
            }
            
            // MARK: GET ALL CATEGORIES
            TCPClient.shared.sendCommand("DATAGET TYPES.txt", type: .download) { response in
                switch response {
                case .success(code: _, message: _):
                    print("Error: Expeced to recieve data")
                case .content(data: let data):
                    for line in data.split(separator: "\n") {
                        if let newCategory = UnitouchCategory(raw:String(line)) {
                            self.backendData.categories.append(newCategory)
                        }
                    }
                case .error(let error):
                    print("Error: \(error)")
                }
            }
            
            // MARK: GET ALL ITEMS
            TCPClient.shared.sendCommand("DATAGET ART.txt", type: .download) { response in
                switch response {
                case .success(code: _, message: _):
                    print("Error: Expeced to recieve data")
                case .content(data: let data):
                    var temp_cat: [Int] = []
                    
                    for line in data.split(separator: "\n") {
                        if let newProduct = UnitouchProduct(raw:String(line)) {
                            self.backendData.items.append(newProduct)
                            
                            if(!temp_cat.contains(newProduct.page)){
                                temp_cat.append(newProduct.page)
                            }
                        }
                    }
                    
                    for (index, value) in (temp_cat.sorted()).enumerated() {
                        if index == value {continue}
                        for (index1, _) in self.backendData.items.enumerated() {
                            if(self.backendData.items[index1].page == value){
                                self.backendData.items[index1].page = index
                            }
                        }
                    }
                    
                case .error(let error):
                    print("Error: \(error)")
                }
            }
            
            
            // MARK: GET ALL LOOKUPS
            TCPClient.shared.sendCommand("DATAGET REMARKS.txt", type: .download) { response in
                switch response{
                case .success(code: _, message: _):
                    self.activeError = .noDataRecieved
                case .content(data: let data):
                    for line in data.split(separator: "\n") {
                        let parts = line.split(separator: "\t")
                        if let lookup = self.backendData.lookups.first(where: { $0.id == Int(parts[0]) }), let child = Int(parts[1]) {
                            lookup.items.append(child)
                        } else {
                            if let newLookup = UnitouchLookup(raw: String(line)) {
                                self.backendData.lookups.append(newLookup)
                            }
                        }
                    }
                case .error(let error):
                    self.activeError = .unknown(err: "Error: '\(error.localizedDescription)")
                }
            }
            
            
            //MARK: Save to database
            modelContext.insert(self.backendData)
            try modelContext.save()
        } catch {
            self.activeError = error as? UnitouchError
        }
        
    }
    
    // SETUSR
    func setUsers(user: UnitouchUser, setState: Bool = true){
        TCPClient.shared.sendCommand("SETUSR \(user.id) 5") { response in
            switch response {
            case .success(_, _):
                if setState { self.state = .main }
                self.currentUser = user
            case .content(_):
                break
            case .error(let error):
                self.activeError = .unknown(err: error.localizedDescription)
            }
        }
    }
    
    func logout(){
        self.currentUser = nil
        self.state = .userSelection
    }
    
    func resetState(){
        self.state = .main
        self.currentTable = nil
        self.currentTableItems = []
        self.currentSubTables = []
    }
    
    func closeTable(){
        TCPClient.shared.sendCommand("ACCCLOSE") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.state = .main
                    self.resetState()
                }else {
                    self.activeError = .unknown(err: "Onverwachte response bij het verlaten van tafel: \(code) \(message)")
                }
            case .content(_):
                self.activeError = .unknown(err: "Onverwachte response bij het verlaten van tafel")
            case .error(let error):
                self.activeError = .unknown(err: "Onverwachte response bij het verlaten van tafel: \(error)")
            }
        }
    }
    
    
    // MARK: Functions for checking if a table consists of sub tables
    func checkSubTable(table: TableInfo, nextState: SubTableActions){
        currentSubTables = []
        TCPClient.shared.sendCommand("PLSTSPLIT \(table.formatTableRaw)", type: .download) { response in
            switch response {
            case .success(let code , let message):
                self.activeError = .unknown(err: "Onverwachte response bij splitsing status van tafel: \(code) \(message)")
            case .content(let data):
                for line in data.split(separator: "\n") {
                    if let info = SubTableInfo(raw: String(line)){
                        self.currentSubTables.append(info)
                    }
                }
                
                /// PLSTSPLIT returns nothing if the table is not split
                if self.currentSubTables.isEmpty {
                    self.continueSubTable(nextTable: table, nextState: nextState)
                } else {
                    self.state = .splitSelection(table: table, nextState: nextState)
                }
            case .error(_):
                self.activeError = .unknown(err: "Kon splitsing status van tafel niet controleren")
            }
        }
    }
    
    func continueSubTable(nextTable: TableInfo, nextState: SubTableActions){
        switch nextState {
        case .openTable:
            self.enterTable(table: nextTable)
        case .moveTable:
            if self.currentTable != nil {
                self.finishMoveTable(newTable: nextTable)
            } else {
                self.startMoveTable(newTable: nextTable)
            }
        case .splitTable:
            self.finishSplitTable(newTable: nextTable)
        case .payTable:
            print()
            //TODO: session.payTable(table: newTable)
        }
    }
    
    
    // MARK: Functions for entring tables
    func enterTable(table: TableInfo){
        TCPClient.shared.sendCommand("ACCGETALL 1 \(table.formatTableRaw)", type: .download) { response in
            switch response {
            case .success(let code, let message):
                self.resetState()
                switch code {
                case 401:
                    self.activeError = .tableLocked
                default:
                    self.activeError = .unknown(err: "Onverwachte response bij openen tafel: \(code) \(message)")
                }
            case .content(let data):
                for line in data.split(separator: "\n") {
                    if let item = NewItem(raw: String(line)) {
                        self.currentTableItems.append(item)
                    }
                }
                
                self.currentTable = table
                self.state = .order
            case .error(let error):
                self.resetState()
                print("Error: \(error)")
            }
        }
    }
    
    func finishTable(newItems: [NewItem], deletedItems: [NewItem]){
        // Close table if no changes were made
        if newItems.isEmpty && deletedItems.isEmpty {
            TCPClient.shared.sendCommand("ACCCLOSE") { response in
                switch response {
                case .success(_, _):
                    self.resetState()
                case .content(data: _):
                    self.activeError = .unknown(err: "Kon tafel niet sluiten")
                case .error(let error):
                    self.activeError = .unknown(err: "Kon tafel niet sluiten, error: \(error)")
                }
            }
            return
        }
        
        guard let table = currentTable else {
            self.activeError = .unknown(err: "Geen actieve tafel geselecteerd")
            return
        }
        
        // Convert data to String
        var data = ""
        for item in newItems  {
            data += item.outputNew
        }
        for item in deletedItems {
            data += item.outputDelete
        }
        
        // Upload new items and deleted items to server
        TCPClient.shared.sendUploadCommand("ACCPUT 1 \(table.formatTableRaw)", payload: data) { response in
            switch response {
            case .success(_, _):
                self.state = .main
                self.currentTable = nil
                self.currentTableItems = []
            case .content(data: _):
                self.activeError = .unknown(err: "Kon tafel niet sluiten")
            case .error(let error):
                self.activeError = .unknown(err: "Kon tafel niet sluiten, error: \(error)")
            }
        }
    }
    
    
    // MARK: Functions for moving tables
    func startMoveTable(newTable: TableInfo) {
        TCPClient.shared.sendCommand("ACCGET 1 \(newTable.formatTableRaw)") { response in
            switch response {
            case .success(let code, let message):
                if code == 201 {
                    self.currentTable = newTable
                    self.state = .main
                }else if code == 401 {
                    self.activeError = .tableLocked
                }else {
                    self.activeError = .unknown(err: "Onverwachte response bij verplaatsen tafel: \(code) \(message)")
                }
            case .content(_):
                self.activeError = .unknown(err: "Onverwachte response bij verplaatsen tafel")
            case .error(let error):
                self.activeError = .unknown(err: "Onverwachte response bij verplaatsen tafel: \(error)")
            }
        }
    }
    
    func finishMoveTable(newTable: TableInfo) {
        guard
            let currentTable = self.currentTable
        else {
            self.activeError = .unknown(err: "Geen actieve tafel geselecteerd")
            return
        }
        TCPClient.shared.sendCommand("ACCMOVE 1 \(currentTable.formatTableRaw) 1 \(newTable.formatTableRaw)") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.state = .main
                    self.currentTable = nil
                }else if code == 401 {
                    self.activeError = .tableLocked
                }else {
                    self.activeError = .unknown(err: "Onverwachte response bij verplaatsen tafel: \(code) \(message)")
                }
            case .content(_):
                self.activeError = .unknown(err: "Onverwachte response bij verplaatsen tafel")
            case .error(let error):
                self.activeError = .unknown(err: "Onverwachte response bij verplaatsen tafel: \(error)")
            }
        }
    }
    
    // MARK: Functions for splitting tables
    func startSplitTable() {
        guard
            self.currentTable != nil
        else {
            self.activeError = .unknown(err: "Geen actieve tafel geselecteerd")
            return
        }
        self.state = .splitTable(nextAction: .move)
    }
    
    func continueSplitTable() {
        guard case let .splitTable(nextAction) = self.state else { return }
        let next = nextAction
            
        if next == .move {
            self.state = .main
        } else {
            let paymentTable = TableInfo(rawTable: "1001.0")
            finishSplitTable(newTable: paymentTable)
            
            startPayment(table: paymentTable)
        }
    }
    
    func finishSplitTable(newTable: TableInfo) {
        guard
            let currentTable = self.currentTable
        else {
            return
        }
        
        let items = self.currentTableItems.filter { $0.splitMove > 0 }
        let data = items.map { $0.outputSplitMove }.joined()
        
        TCPClient.shared.sendUploadCommand("ACCSPLIT 1 \(currentTable.formatTableRaw) 1 \(newTable.formatTableRaw)", payload: data, completion: { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.resetState()
                } else {
                    self.activeError = .unknown(err: "Onverwachte response bij splitsen tafel: \(code) \(message)")
                }
            case .content(_):
                break
            case .error(let error):
                self.activeError = .unknown(err: "Onverwachte response bij splitsen tafel: \(error)")
            }
        })
    }
    
    
    
    
    // MARK: Functions for paying tables
    func startPayment(table: TableInfo){
        TCPClient.shared.sendCommand("ACCBILL 1 \(table.formatTableRaw)") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    guard
                        let balance = Double(message.trimmingCharacters(in: .whitespacesAndNewlines))
                    else {
                        self.activeError = .unknown(err: "Kon bedrag niet ophalen van de server") // MAKE ERROR
                        return
                    }
                    TCPClient.shared.sendCommand("GETBILL", type: .download) { response in
                        switch response {
                        case .content(let data):
                            self.state = .payment(balance: Double(balance), bill: data)
                            self.currentTable = table
                        case .error(let error):
                            self.activeError = .unknown(err: "Onverwachte response bij betalen tafel: \(error)")
                        case .success:
                            self.state = .payment(balance: Double(balance), bill: "")
                            self.currentTable = table
                        }
                    }
                } else{
                    self.resetState()
                    if(code == 401) {
                        self.activeError = .tableLocked
                    } else if (code == 406){
                        self.activeError = .tableEmpty
                    } else {
                        self.activeError = .unknown(err: "Onverwachte response bij betalen tafel: \(code) \(message)")
                    }
                }
            case .content(let data):
                print(data)
                break
            case .error(let error):
                self.activeError = .unknown(err: "Onverwachte response bij betalen tafel: \(error)")
            }
        }
    }
    
    func finishPayment(methodId: Int, methodName: String){
        guard
            let currentTable = self.currentTable,
            let currentUser = self.currentUser
        else {
            self.activeError = .unknown(err: "Geen actieve tafel geselecteerd")
            return
        }
        TCPClient.shared.sendUploadCommand("ACCPAY 1 \(currentTable.formatTableRaw)",
                                           payload: "\(methodId)\t\(methodName)\t\(currentUser.id)\t1\t1\t\(currentUser.name)\t\t0\tRepBillSmall\t0") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.resetState()
                } else {
                    self.activeError = .unknown(err: "Onverwachte response bij afronden betaling: \(code) \(message)")
                }
            case .error(let error):
                self.activeError = .unknown(err: "Onverwachte response bij afronden betaling: \(error)")
            case .content(_):
                break
            }
        }
    }
    
    func vivaPayment(amount: Double, total: Double){
        guard
            let currentTable = self.currentTable,
            let currentUser = self.currentUser,
            total == 0 || total >= amount
        else { return }
        let clientTransactionId = "\(currentUser.id)-\(currentUser.name)-\(currentTable.formatTableRaw)"
        let tipAmount = total - amount
        guard
            let url = URL(string: "vivapayclient://pay/v1?callback=unitouch&merchantKey=1570006a-b5c8-ed11-b597-0022489e30c9&appId=com.tijngiesberts.unitouch&action=sale&amount=\(Int(amount*100))&tipAmount=\(Int(tipAmount*100))&clientTransactionId=\(clientTransactionId)")
        else {
            self.activeError = .invalidVivaWalletURL
            return
        }
        

        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                self.activeError = .unknown(err: "Kon Viva Wallet niet openen")
            }
        }
        
    }
    
    func finishVivaPayment(table: TableInfo, amount: Double, tipAmount: Double, userId: Int, userName: String){
        /// The application went to sleep and the connection was closed, meaning we have to check wether the table is still available
        if self.currentTable == nil {
            TCPClient.shared.sendCommand("ACCBILL 1 \(table.formatTableRaw)") { response in
                switch response {
                case .success(let code, let message):
                    guard
                        let balance = Double(message.trimmingCharacters(in: .whitespacesAndNewlines)),
                        code == 200
                    else {
                        self.activeError = .vivaPaymentProcessingError(message: message)
                        return
                    }
                    if balance != amount {
                        self.activeError = .vivaBalanceMismatch(expected: balance, received: amount)
                    } else {
                        TCPClient.shared.sendUploadCommand("ACCPAY 1 \(table.formatTableRaw)",
                                                           payload: "97\tInterpay Plus\t\(userId)\t1\t1\t\(userName)\t\t0\tRepBillSmall\t0") { response in
                            switch response {
                            case .success(let code, let message):
                                if code == 200 {
                                    self.resetState()
                                } else {
                                    self.activeError = .vivaPaymentProcessingError(message: message)
                                }
                            case .error(let error):
                                self.activeError = .vivaPaymentProcessingError(message: error.localizedDescription)
                            case .content(_):
                                break
                            }
                        }
                        
                    }
                case .content(_):
                    break
                case .error(let error):
                    self.activeError = .vivaPaymentProcessingError(message: error.localizedDescription)
                }
            }
            
        } else {
            self.finishPayment(methodId: 97, methodName: "Interpay Plus")
            self.resetState()
        }
    }
}
