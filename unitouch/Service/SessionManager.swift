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
    case splitSelection(table: TableInfo, nextState: SubTableActions)
    case main                                                           // Screen 3: Main Input
    case splitTable                                                     // Screen 4: Split Table
    case order                                                          // Screen 4: The "Move or Pay" logic
    case payment(balance: Decimal, bill: String)
    case tableMap(nextState: SubTableActions)
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

struct blockedItem {
    var plu: Int
    var count: Int
}


@MainActor
class SessionManager: ObservableObject {
    // State
    @Published var state: AppState = .disconnected
    @Published var preservedState: AppState? = nil
    @Published var activeError: UnitouchError? = nil
    
    // Global Data
    @Published var backendData: BackendData = BackendData()
    
    // Persistent Memory
    var currentUser: UnitouchUser?
    var currentTable: TableInfo?
    @Published var currentTableItems: [NewItem] = []
    @Published var newItems: [NewItem] = []
    @Published var deletedItems: [NewItem] = []
    var currentSubTables: [SubTableInfo] = []
    @Published var openTables: [OpenTable] = []
    var blockedItems: [blockedItem] = []
    @Published var requestNumberOfPeople: Bool = false
    @Published var requestMoveConformation: TableInfo? = nil
    
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
    
    func verifyData() async {
        self.state = .loading("Checking for updates...")
        self.backendData = DataManager.shared.load(forKey: "backendData", as: BackendData.self) ?? BackendData()
        TCPClient.shared.sendCommand("DATAGET TIMESTAMP.txt", type: .download) { response in
            switch response{
            case .content(data: let timestamp):
                if timestamp.trimmingCharacters(in: .whitespacesAndNewlines) != self.backendData.timestamp.trimmingCharacters(in: .whitespacesAndNewlines) {
                    Task{
                        print("Timestamp mismatch, updating data...")
                        self.backendData.reset(timestamp)
                        await self.getData()
                        self.state = .userSelection
                    }
                } else {
                    self.state = .userSelection
                }
            case .error(let error):
                self.activeError = .dataSyncFailed(details: error.localizedDescription)
                print("Error: \(error)")
            default:
                self.activeError = .invalidServerResponse(action: "controleren timestamp", details: "Onverwachte response")
            }
        }
    }
    
    // MARK: Data Retrieval
    func getData() async {
        // MARK: GET ALL USERS
        TCPClient.shared.sendCommand("DATAGET WAITER.txt", type: .download) { response in
            switch response {
            case .content(data: let data):
                for line in data.split(separator: "\n") {
                    if let newUser = UnitouchUser(raw:String(line)) {
                        self.backendData.users.append(newUser)
                    }
                }
            case .error(let error):
                self.activeError = .dataSyncFailed(details: error.localizedDescription)
                print("Error: \(error)")
            default:
                self.activeError = .invalidServerResponse(action: "ophalen gebruikers", details: "Onverwachte response")
            }
        }
        
        // MARK: GET ALL CATEGORIES
        TCPClient.shared.sendCommand("DATAGET TYPES.txt", type: .download) { response in
            switch response {
            case .content(data: let data):
                for line in data.split(separator: "\n") {
                    if let newCategory = UnitouchCategory(raw:String(line)) {
                        self.backendData.categories.append(newCategory)
                    }
                }
            case .error(let error):
                self.activeError = .dataSyncFailed(details: error.localizedDescription)
                print("Error: \(error)")
            default:
                self.activeError = .invalidServerResponse(action: "ophalen categorieën", details: "Onverwachte response")
            }
        }
        
        // MARK: GET ALL ITEMS
        TCPClient.shared.sendCommand("DATAGET ART.txt", type: .download) { response in
            switch response {
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
                self.activeError = .dataSyncFailed(details: error.localizedDescription)
                print("Error: \(error)")
            default:
                self.activeError = .invalidServerResponse(action: "ophalen producten", details: "Onverwachte response")
            }
        }
        
        // MARK: GET ALL LOOKUPS
        TCPClient.shared.sendCommand("DATAGET REMARKS.txt", type: .download) {response in
            switch response{
            case .content(data: let data):
                for line in data.split(separator: "\n") {
                    let parts = line.split(separator: "\t")
                    if let index = self.backendData.lookups.firstIndex(where: { $0.id == Int(parts[0]) }), let child = Int(parts[1]) {
                        self.backendData.lookups[index].items.append(child)
                    } else {
                        if let newLookup = UnitouchLookup(raw: String(line)) {
                            self.backendData.lookups.append(newLookup)
                        }
                    }
                }
            case .error(let error):
                self.activeError = .dataSyncFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "ophalen opmerkingen", details: "Onverwachte response")
            }
        }
        
        // MARK: GET ALL BACKGROUNDS
        for i in 1...7 {
            let filename = "288-back0\(i).jpg"
            TCPClient.shared.sendCommand("BINDATAGET \(filename)", type: .image) { response in
                switch response {
                case .binary(let imageData):
                    if let _ = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self.backendData.backgrounds.append(UnitouchBackground(id: i, imageData: imageData))
                        }
                    } else {
                        print("❌ Failed to create UIImage from data")
                    }
                case .error(let error):
                    print("❌ Image Fetch Error: \(error.localizedDescription)")
                case .success(let code, let message):
                    print("⚠️ Unexpected text response: \(code) \(message)")
                case .content(_):
                    break
                }
            }
        }
        
        // MARK: GET ALL TABLES
        TCPClient.shared.sendCommand("DATAGET TBLCELL.txt", type: .download) { response in
            switch response {
            case .content(data: let data):
                for line in data.split(separator: "\n") {
                    if let newTable = UnitouchTable(raw: String(line)) {
                        self.backendData.tables.append(newTable)
                    }
                }
            case .error(let error):
                self.activeError = .dataSyncFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "ophalen tafels", details: "Onverwachte response")
            }
        }
        
        // MARK: GET ALL COLORS
        TCPClient.shared.sendCommand("DATAGET TBLCOLORS.txt", type: .download) { response in
            switch response {
            case .content(let data):
                let values = data.split(separator: "\t")
                
                for i in 0...(values.count/2-1) {
                    guard
                        let BTNFill = Int(values[i*2]),
                        let BTNText = Int(values[i*2+1])
                    else { continue }
                    
                    self.backendData.tableColors.append(
                        UnitouchTableColor(
                            BTNStatus: i,
                            BTNFill: BTNFill,
                            BTNText: BTNText
                        )
                    )
                }
            case .error(let error):
                self.activeError = .dataSyncFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "ophalen tafelkleuren", details: "Onverwachte response")
            }
        }
        
        //MARK: Save to database
        TCPClient.shared.sendCommand("TEST", type: .download) { _ in
            DataManager.shared.save(self.backendData, forKey: "backendData")
        }

    }
    
    // SETUSR
    func setUsers(user: UnitouchUser, setState: Bool = true){
        TCPClient.shared.sendCommand("SETUSR \(user.id) 5") { response in
            switch response {
            case .success(_, _):
                if setState { self.state = .main }
                self.currentUser = user
            case .error(let error):
                self.activeError = .userLoginFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "gebruiker inloggen", details: "Onverwachte response")
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
        self.requestNumberOfPeople = false
    }
    
    func closeTable(){
        TCPClient.shared.sendCommand("ACCCLOSE") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.state = .main
                    self.resetState()
                } else {
                    self.activeError = .closeTableFailed(details: "\(code) \(message)")
                }
            case .error(let error):
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "tafel sluiten", details: "Onverwachte response")
            }
        }
    }
    
    func getOpenTables() {
        self.openTables = []
        TCPClient.shared.sendCommand("PLSTOPEN 1", type: .download) { response in
            switch response {
            case .content(let data):
                for line in data.split(separator: "\n") {
                    if let info = OpenTable(raw: String(line)){
                        self.openTables.append(info)
                    }
                }
            case .error(let error):
                self.activeError = .fetchOpenTablesFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "ophalen open tafels", details: "Onverwachte response")
            }
        }
    }
    
    
    // MARK: Functions for checking if a table consists of sub tables
    func checkSubTable(table: TableInfo, nextState: SubTableActions){
        currentSubTables = []
        TCPClient.shared.sendCommand("PLSTSPLIT \(table.formatTableFlat)", type: .download) { response in
            switch response {
            case .content(let data):
                for line in data.split(separator: "\n") {
                    if let info = SubTableInfo(raw: String(line)){
                        self.currentSubTables.append(info)
                    }
                }
                
                if self.currentSubTables.isEmpty {
                    self.continueSubTable(nextTable: table, nextState: nextState)
                } else {
                    self.state = .splitSelection(table: table, nextState: nextState)
                }
            case .error(let error):
                self.activeError = .checkSubTableFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "controleren splitsing status", details: "Onverwachte response")
            }
        }
    }
    
    func continueSubTable(nextTable: TableInfo, nextState: SubTableActions){
        switch nextState {
        case .openTable:
            self.enterTable(table: nextTable)
        case .moveTable:
            if self.currentTable != nil {
                self.checkMoveState(newTable: nextTable)
            } else {
                self.startMoveTable(newTable: nextTable)
            }
        case .splitTable:
            self.checkMoveState(newTable: nextTable)
        case .payTable:
            self.startPayment(table: nextTable)
        }
    }
    
    
    // MARK: Functions for entring tables
    func enterTable(table: TableInfo){
        TCPClient.shared.sendCommand("ACCGETALL 1 \(table.formatTableFlat)", type: .download) { response in
            switch response {
            case .success(let code, let message):
                self.resetState()
                switch code {
                case 401:
                    self.activeError = .tableLocked
                default:
                    self.activeError = .openTableFailed(details: "\(code) \(message)")
                }
            case .content(let data):
                self.currentTableItems = []
                for line in data.split(separator: "\n") {
                    if let item = NewItem(raw: String(line)) {
                        self.currentTableItems.append(item)
                    }
                }
                
                self.currentTable = table
                self.state = .order
            case .error(let error):
                self.resetState()
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "tafel openen", details: "Onverwachte response")
            }
        }
        self.blockedItems = []
        TCPClient.shared.sendCommand("GETPLULOCKS2", type: .download) { response in
            switch response {
            case .success(_, let message):
                let items = message.split(separator: "/")
                for item in items{
                    let plu = item.split(separator: ":")[0]
                    let count = item.split(separator: ":")[1]
                    
                    if let pluInt = Int(plu), let countInt = Int(count) {
                        self.blockedItems.append(blockedItem(plu: pluInt, count: countInt))
                    }
                }
            case .error:
                self.activeError = .noBlockedItemsReceived
            default:
                self.activeError = .invalidServerResponse(action: "ophalen geblokkeerde items", details: "Onverwachte response")
            }
        }
        
        TCPClient.shared.sendCommand("GETNRP 1 \(table.formatTableFlat)") { response in
            switch response {
            case .success(_, let message):
                guard let number = Int(message) else {
                    if (self.activeError == nil) {
                        self.activeError = .fetchNumberOfPeopleFailed(details: "Ongeldig aantal ontvangen: \(message)")
                    }
                    return
                }
                
                if number == 0 {
                    self.requestNumberOfPeople = true
                }
            case .error(let error):
                if (self.activeError == nil) {
                    self.activeError = .fetchNumberOfPeopleFailed(details: error.localizedDescription)
                }
            default:
                self.activeError = .invalidServerResponse(action: "ophalen aantal personen", details: "Onverwachte response")
            }
        }
    }
    
    func setNumberOfPeople(count: Int) {
        guard let currentTable = self.currentTable else {
            self.activeError = .noActiveTable
            return
        }
        TCPClient.shared.sendCommand("SETNRP 1 \(currentTable.formatTableFlat) \(count)") { response in
            switch response {
            case .success(_, _):
                self.requestNumberOfPeople = false
            case .error(let error):
                self.activeError = .setNumberOfPeopleFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "opslaan aantal personen", details: "Onverwachte response")
            }
        }
    }
    
    func finishTable(newItems: [NewItem], deletedItems: [NewItem], closeTable: Bool = true){
        // Close table if no changes were made
        if newItems.isEmpty && deletedItems.isEmpty {
            if closeTable == false { return }
            TCPClient.shared.sendCommand("ACCCLOSE") { response in
                switch response {
                case .success(_, _):
                    self.resetState()
                case .error(let error):
                    self.activeError = .closeTableFailed(details: error.localizedDescription)
                default:
                    self.activeError = .invalidServerResponse(action: "tafel sluiten", details: "Onverwachte response")
                }
            }
            return
        }
        
        guard let table = currentTable else {
            self.activeError = .noActiveTable
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
        TCPClient.shared.sendUploadCommand("ACCPUT 1 \(table.formatTableFlat)", payload: data) { response in
            switch response {
            case .success(_, _):
                if closeTable {
                    self.state = .main
                    self.currentTable = nil
                    self.currentTableItems = []
                } else {
                    let itemsToAdd = newItems.filter { !self.currentTableItems.contains($0) }
                    let itemsToRemove = deletedItems.filter { self.currentTableItems.contains($0) }
                    var updated = self.currentTableItems + itemsToAdd
                    updated.removeAll(where: { itemsToRemove.contains($0) })
                    self.currentTableItems = updated
                }
                self.newItems = []
                self.deletedItems = []
            case .error(let error):
                self.activeError = .closeTableFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "bestelling opslaan", details: "Onverwachte response")
            }
        }
    }
    
    func addBlockedItem(plu: Int, count: Int, completion: (() -> Void)? = nil) {
        TCPClient.shared.sendCommand("ADDPLULCKCNT \(plu) \(count)") {response in
            switch response {
            case .success(let code, let message):
                switch code {
                case 200:
                    completion?()
                case 425:
                    self.activeError = .invalidBlockedItemQuantity
                default:
                    self.activeError = .addBlockedItemFailed(details: "\(code) \(message)")
                }
            case .error(let error):
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "item blokkeren", details: "Onverwachte response")
            }
            
        }
    }
    
    
    // MARK: Functions for moving tables
    func startMoveTable(newTable: TableInfo) {
        TCPClient.shared.sendCommand("ACCGET 1 \(newTable.formatTableFlat)") { response in
            switch response {
            case .success(let code, let message):
                if code == 201 {
                    self.currentTable = newTable
                    self.state = .main
                } else if code == 401 {
                    self.activeError = .tableLocked
                } else {
                    self.activeError = .moveTableFailed(details: "\(code) \(message)")
                }
            case .error(let error):
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "tafel verplaatsen starten", details: "Onverwachte response")
            }
        }
    }
    
    func checkMoveState(newTable: TableInfo) {
        TCPClient.shared.sendCommand("ACCSTATE 1 \(newTable.formatTableFlat)") { response in
            switch response {
            case .success(let code, let message):
                switch message {
                case "1":
                    // Table is Empty, can move directly
                    if self.currentTableItems.isEmpty{
                        self.finishMoveTable(newTable: newTable)
                    } else {
                        self.finishSplitTable(newTable: newTable)
                    }
                case "2":
                    // Table has items, check before moving
                    self.requestMoveConformation = newTable
                case "5":
                    // Table is in use but is empty, give error that it cant move
                    self.activeError = .tableLocked
                case "6":
                    // Table is in use and has items, give error that it cant move
                    self.activeError = .tableLocked
                default:
                    self.activeError = .moveTableFailed(details: "\(code) \(message)")
                }
            case .error(let error):
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "status tafel verplaatsen", details: "Onverwachte response")
            }
        }
    }
    
    func finishMoveTable(newTable: TableInfo) {
        guard
            let currentTable = self.currentTable
        else {
            self.activeError = .noActiveTable
            return
        }
        TCPClient.shared.sendCommand("ACCMOVE 1 \(currentTable.formatTableFlat) 1 \(newTable.formatTableFlat)") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.state = .main
                    self.currentTable = nil
                    self.requestMoveConformation = nil
                } else if code == 401 {
                    self.activeError = .tableLocked
                } else {
                    self.activeError = .moveTableFailed(details: "\(code) \(message)")
                }
            case .error(let error):
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "tafel verplaatsen afronden", details: "Onverwachte response")
            }
        }
    }
    
    // MARK: Functions for splitting tables
    func startSplitTable() {
        guard
            self.currentTable != nil
        else {
            self.activeError = .noActiveTable
            return
        }
        self.state = .splitTable
    }
    
    func continueSplitTable(next: SplitTableActions) {
        guard case .splitTable = self.state else { return }
        
        if next == .move {
            self.state = .main
        } else if next == .pay {
            let userId = self.currentUser?.id ?? 0
            let paymentTable = TableInfo(rawTable: "\(userId + 1000).0")
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
        
        TCPClient.shared.sendUploadCommand("ACCSPLIT 1 \(currentTable.formatTableFlat) 1 \(newTable.formatTableFlat)", payload: data, completion: { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.resetState()
                    self.requestMoveConformation = nil
                } else {
                    self.activeError = .splitTableFailed(details: "\(code) \(message)")
                }
            case .error(let error):
                self.activeError = .splitTableFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "tafel splitsen", details: "Onverwachte response")
            }
        })
    }
    
    // MARK: Functions for paying tables
    func startPayment(table: TableInfo){
        TCPClient.shared.sendCommand("ACCBILL 1 \(table.formatTableFlat)") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    guard
                        let balance = Decimal(string: message.trimmingCharacters(in: .whitespacesAndNewlines))
                    else {
                        self.activeError = .fetchBillFailed(details: "Kon bedrag niet parsen: \(message)")
                        return
                    }
                    TCPClient.shared.sendCommand("GETBILL", type: .download) { response in
                        switch response {
                        case .content(let data):
                            self.state = .payment(balance: balance, bill: data)
                            self.currentTable = table
                        case .error(let error):
                            self.activeError = .fetchBillFailed(details: error.localizedDescription)
                        case .success:
                            self.state = .payment(balance: balance, bill: "")
                            self.currentTable = table
                        default:
                            self.activeError = .invalidServerResponse(action: "rekening ophalen", details: "Onverwachte response")
                        }
                    }
                } else {
                    self.resetState()
                    if(code == 401) {
                        self.activeError = .tableLocked
                    } else if (code == 406){
                        self.activeError = .tableEmpty
                    } else {
                        self.activeError = .fetchBillFailed(details: "\(code) \(message)")
                    }
                }
            case .error(let error):
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "starten betaling", details: "Onverwachte response")
            }
        }
    }
    
    func finishPayment(methodId: Int, methodName: String, modelContext: ModelContext, amount: Decimal, tip: Decimal){
        guard
            let currentTable = self.currentTable,
            let currentUser = self.currentUser
        else {
            self.activeError = .noActiveTable
            return
        }
        TCPClient.shared.sendUploadCommand("ACCPAY 1 \(currentTable.formatTableFlat)",
                                           payload: "\(methodId)\t\(methodName)\t\(currentUser.id)\t1\t1\t\(currentUser.name)\t\t0\tRepBillSmall\t0") { response in
            switch response {
            case .success(let code, let message):
                if code == 200 {
                    self.resetState()
                    
                    let payment = Payment(
                        user: currentUser.name,
                        table: currentTable.formatTableRaw,
                        amount: amount,
                        tip: tip
                    )
                    
                    modelContext.insert(payment)
                   do {
                        try modelContext.save()
                   } catch {
                       print("⚠️ Failed to save payment: \(error)")
                   }
                } else {
                    self.activeError = .paymentCompletionFailed(details: "\(code) \(message)")
                }
            case .error(let error):
                self.activeError = .networkError(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "afronden betaling", details: "Onverwachte response")
            }
        }
    }
    
    func vivaPayment(amount: Decimal, total: Decimal){
        guard
            let currentTable = self.currentTable,
            let currentUser = self.currentUser,
            total == 0 || total >= amount
        else { return }
        let clientTransactionId = "\(currentUser.id)-\(currentUser.name)-\(currentTable.formatTableFlat)"
        let tipAmount = total - amount
        let tipString = tipAmount > 0 ? "&tipAmount=\(NSDecimalNumber(decimal: tipAmount*100))" : ""
        guard
            let url = URL(string: "vivapayclient://pay/v1?callback=unitouch&merchantKey=1570006a-b5c8-ed11-b597-0022489e30c9&appId=com.tijngiesberts.unitouch&action=sale&amount=\(NSDecimalNumber(decimal: amount*100))\(tipString)&clientTransactionId=\(clientTransactionId)")
        else {
            self.activeError = .invalidVivaWalletURL
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                self.activeError = .openingVivaWalletFailed
            }
        }
        
    }
    
    func finishVivaPayment(table: TableInfo, amount: Double, tipAmount: Double, userId: Int, userName: String, modelContext: ModelContext){
        /// The application went to sleep and the connection was closed, meaning we have to check wether the table is still available
        if self.currentTable == nil {
            TCPClient.shared.sendCommand("ACCBILL 1 \(table.formatTableFlat)") { response in
                switch response {
                case .success(let code, let message):
                    guard
                        let balance = Double(message.trimmingCharacters(in: .whitespacesAndNewlines)),
                        code == 200
                    else {
                        self.activeError = .vivaPaymentProcessingError(details: message)
                        return
                    }
                    if balance != amount {
                        self.activeError = .vivaBalanceMismatch(expected: balance, received: amount)
                    } else {
                        TCPClient.shared.sendUploadCommand("ACCPAY 1 \(table.formatTableFlat)",
                                                           payload: "97\tInterpay Plus\t\(userId)\t1\t1\t\(userName)\t\t0\tRepBillSmall\t0") { response in
                            switch response {
                            case .success(let code, let message):
                                if code == 200 {
                                    self.resetState()
                                    
                                    let payment = Payment(
                                        user: userName,
                                        table: table.formatTableRaw,
                                        amount: Decimal(amount),
                                        tip: Decimal(tipAmount)
                                    )
                                    modelContext.insert(payment)
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("⚠️ Failed to save payment: \(error)")
                                    }
                                } else {
                                    self.activeError = .vivaPaymentProcessingError(details: "\(code) \(message)")
                                }
                            case .error(let error):
                                self.activeError = .vivaPaymentProcessingError(details: error.localizedDescription)
                            default:
                                self.activeError = .invalidServerResponse(action: "viva betaling opslaan", details: "Onverwachte response")
                            }
                        }
                        
                    }
                case .error(let error):
                    self.activeError = .vivaPaymentProcessingError(details: error.localizedDescription)
                default:
                    self.activeError = .invalidServerResponse(action: "viva betaling controleren", details: "Onverwachte response")
                }
            }
            
        } else {
            self.finishPayment(methodId: 97, methodName: "Interpay Plus", modelContext: modelContext, amount: Decimal(amount), tip: Decimal(tipAmount))
            self.resetState()
        }
    }
    
    // MARK: Functions for table map
    func startTableMap(nextState: SubTableActions){
        TCPClient.shared.sendCommand("PLSTOPEN 1", type: .download) { response in
            switch response{
            case .content(let data):
                self.openTables = []
                for line in data.split(separator: "\n") {
                    if let info = OpenTable(raw: String(line)){
                        print(info)
                        self.openTables.append(info)
                    }
                }
                self.state = .tableMap(nextState: nextState)
            case .error(let error):
                self.activeError = .openTableMapFailed(details: error.localizedDescription)
            default:
                self.activeError = .invalidServerResponse(action: "tafel plattegrond openen", details: "Onverwachte response")
            }
        }
    }
}
