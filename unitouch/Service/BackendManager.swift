//
//  BackendManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable class BackendManager: NetworkManager {
    static let shared = BackendManager()
    
    // MARK: Table Data
    var activeTable: Int? = nil
    var activeSubTable: Int? = nil
    
    var activeItems: [NewItem] = []
    var splitTables: [SubTable] = []
    var balance: Double? = nil
    
    
   
    // MARK: Global Data
    var backendData: BackendData = BackendData()
    var statusError: UnitouchError? = nil
    var appState: UnitouchState = .setup
    var activeUser : UnitouchUser? = nil
    var vivaPaymentReceived: Bool = false
    
    
    var modelContext: ModelContext?
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func loadBackendData(_ backendData: BackendData) {
        self.backendData = backendData
    }
    
    
    override func setup(reconnect: Bool = false) async {
        //await super.setup(reconnect: reconnect)
        do {
            print("Checking for welcome message")
            try await self.expectFirstMessage("100 Welcome #006082054")
            
            // Get timestamp and check if current backend data is up-to-date
            sendMessage(message: "DATAGET TIMESTAMP.txt")
            
            print("Checking for ready message")
            try await self.expectFirstMessage("201 Ready")
            
            print("Getting timestamp")
            if let timestamp = (try await getUntilEnd()).first {
                if(backendData.timestamp != timestamp) {
                    backendData.reset(timestamp)
                    await getData()
                }
            }
            
            if(reconnect) {
                print("Reconnecting to backend...")
                await self.reconnectBackend()
            }else {
                print("Going to login")
                self.appState = .login
            }
            
            self.connectionState = .ready
            
            if(vivaPaymentReceived){
                self.vivaPaymentReceived = false
                await self.finishPayment(method: "97\tViva Wallet")
            }
            
        } catch{
            print("Error during setup: \(error)")
            self.statusError = error as? UnitouchError
        }
    }
    
    private func getData() async{
        do {
            // MARK: GET ALL USERS
            sendMessage(message: "DATAGET WAITER.txt")
            try await expectFirstMessage("201 Ready")
            
            for line in try await getUntilEnd() {
                if let user = UnitouchUser(raw: line) {
                    backendData.users.append(user)
                } else {
                    print("Invalid user data: \(line)")
                }
            }

            
            // MARK: GET ALL CATEGORIES
            self.sendMessage(message: "DATAGET TYPES.txt")
            try await self.expectFirstMessage("201 Ready")
            
            
            let categoryData = try await self.getUntilEnd()
            for line in categoryData {
                let fields = line.components(separatedBy: "\t")
                if(fields.count == 2) { // There is a price
                    backendData.categories.append(UnitouchCategory(
                        id: Int(fields[0]) ?? -1,
                        name: fields[1]
                    ) )
                }
            }
            
            
            
            // MARK: GET ALL ITEMS
            self.sendMessage(message: "DATAGET ART.txt")
            try await self.expectFirstMessage("201 Ready")
            
            
            var temp_cat: [Int] = []
            
            let itemData = try await self.getUntilEnd()
            for line in itemData {
                let fields = line.components(separatedBy: "\t")
                
                if(fields.count >= 10 && fields[3].contains(".")) { // There is a price
                    // TODO, move Item creatinon in enum itself
                    backendData.items.append(UnitouchProduct(
                        plu: Int(fields[0]) ?? -1,
                        name: fields[1],
                        page: Int(fields[2]) ?? -1,
                        price: Double(fields[3]) ?? -1.1,
                        unk1: (fields[4] == "T"),
                        unk2: Int(fields[5]) ?? -1,
                        rang: Int(fields[6]) ?? -1,
                        followPrevious: (fields[7] == "T"),
                        unk3: (fields[8] == "T"),
                        unk4: Int(fields[9]) ?? -1
                    ) )
                    
                    if(!temp_cat.contains(Int(fields[2]) ?? -1)){
                        temp_cat.append(Int(fields[2]) ?? -1)
                    }
                }
            }
            
            
            //MARK: Convert all GRP to correct numbers
            for (index, value) in (temp_cat.sorted()).enumerated() {
                if index == value {continue}
                for (index1, _) in backendData.items.enumerated() {
                    if(backendData.items[index1].page == value){
                        backendData.items[index1].page = index
                    }
                }
            }
            
            
            //MARK: Save to database
            if let context = self.modelContext {
                context.insert(backendData)
                try context.save()
            }
        } catch {
            self.statusError = error as? UnitouchError
        }
        
    }
    
    @MainActor
    func reconnectBackend() async {
        do {
            //_ = try await self.receiveFirstMessage() // Welcome message
            
            // ATEMPT TO LOGIN AGAIN
            if let activeUser = self.activeUser {
                try await self.login(user: activeUser)
            }else { self.appState = .login; return }
            
            switch(self.appState) {
                case .setup:
                    self.appState = .login
                case .tableOpen:
                    await self.enterTable()
                default:
                    break
            }
            
                
        } catch {
            print("Error during reconnect: \(error)")
        }
    }
    
    
    //Function
    func login(user: UnitouchUser) async throws {
        sendMessage(message: "SETUSR \(user.id) 5")
        try await expectFirstMessage("200 Ok")
        
        self.activeUser = user
    }
    
    func startTable(next: UnitouchState, tableInfo: TableInfo, closure: @escaping () -> ()) async {
        do {
            if(
                (appState == .selection && !tableInfo.isSubTableSet) ||
                (appState == .movingTable && !tableInfo.isSubTableSet)
            ){
                splitTables = []
                self.sendMessage(message: "PLSTSPLIT \(tableInfo.table)0")
                try await self.expectFirstMessage("201 Ready")
                
                
                let lines = try await self.getUntilEnd()
                for line in lines {
                    let fields = line.components(separatedBy: "\t")
                    if(fields.count >= 7){
                        self.splitTables.append(SubTable(
                            table: fields[0],
                            balance: fields[1],
                            time: fields[2],
                            free: (fields[5] == "Free")
                        ))
                    }
                }
                
                if(!self.splitTables.isEmpty){
                    self.appState = .splitTable(table: tableInfo.table, for: next)
                    return
                }
            }
            
            if(appState != .movingTable) {
                self.activeTable = tableInfo.table
                self.activeSubTable = tableInfo.subTable
            }
            
            closure()
        } catch {
            self.statusError = error as? UnitouchError
        }
    }
    
    //MARK: MOVING TABLE
    func moveTable(newTable: String) async {
        do {
            guard
                let table = activeTable,
                let subTable = activeSubTable
            else { throw UnitouchError.invalidConfiguration }
            
            self.sendMessage(message: "ACCCLOSE")
            try await self.expectFirstMessage("200 Ok")
            
            
            self.sendMessage(message: "ACCSTATE 1 \(newTable)")
            let result = try await self.receiveFirstMessage()
            if result == "200\t1" {
                self.sendMessage(message: "ACCMOVE 1 \(table)\(subTable) 1 \(newTable)")
                try await self.expectFirstMessage("200 Ok")
            }else if result == "200\t2" {
                throw UnitouchError.tableNotEmpty(action: {
                    Task {
                        self.sendMessage(message: "ACCMOVE 1 \(table)\(subTable) 1 \(newTable)")
                        try await self.expectFirstMessage("200 Ok")
                    }
                })
                
            } else if result != "200\t5" || result != "200\t6" {
                throw UnitouchError.tableLocked
            }
        } catch {
            self.statusError = error as? UnitouchError
        }
        
        reset()
    }
    
    func confirmMoveTable(newTable: String) async {
        do {
            guard
                let table = activeTable,
                let subTable = activeSubTable
            else { throw UnitouchError.invalidConfiguration }
            self.sendMessage(message: "ACCMOVE 1 \(table)\(subTable) 1 \(newTable)")
            
            try await self.expectFirstMessage("200 Ok")
        } catch {
            self.statusError = error as? UnitouchError
        }
        
        self.reset()
    }
    
    func cancelMoveTable() async {
        self.sendMessage(message: "ACCCLOSE")
        do {
            try await self.expectFirstMessage("200 Ok")
        } catch {
            self.statusError = error as? UnitouchError
        }
        
        self.reset()
    }
    
    
    
    //MARK: PAYING TABLE
    func startPayment() async {
        do {
            guard
                let table = activeTable,
                let subTable = activeSubTable
            else { throw UnitouchError.invalidConfiguration }
            
            self.sendMessage(message: "ACCBILL 1 \(table)\(subTable)")
            
            let result = try await self.receiveFirstMessage()
            
            if(result == "401 Account Locked") {
                throw UnitouchError.tableLocked
            } else if (result == "406 Account Empty"){
                throw UnitouchError.tableEmpty
            }
            
            let components = result?.components(separatedBy: "\t")

            guard
                let price = components?.last,
                let balance = Double(price)
            else {
                throw UnitouchError.invalidConfiguration
            }
        
            self.balance = balance
            self.activeTable = table
            self.activeSubTable = subTable
            self.appState = .payment
        } catch {
            self.statusError = error as? UnitouchError
        }
    }
    
    func vivaPayment(amount: String) {
        guard
            let table = activeTable,
            let subTable = activeSubTable
        else { self.statusError = UnitouchError.invalidConfiguration; return }
        
        guard
            let url = URL(string: "vivapayclient://pay/v1?callback=unitouch&merchantKey=1570006a-b5c8-ed11-b597-0022489e30c9&appId=com.tijngiesberts.unitouch&action=sale&amount=\(amount)&clientTransactionId=\(table)\(subTable)")
        else { self.statusError = UnitouchError.invalidVivaWalletURL; return }

        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                self.statusError = UnitouchError.openingVivaWalletFailed
            }
        }
    }
    
    func finishPayment(method: String) async {
        do {
            guard
                let table = activeTable,
                let subTable = activeSubTable
            else { throw UnitouchError.invalidConfiguration }
            
            self.sendMessage(message: "ACCPAY\t1\t\(table)\(subTable)")
            
            try await self.expectFirstMessage("201 Ready")

            self.sendMessage(message: "\(method)\t4\t1\t5\tTijn\t\t0\tRepBillSmall\t0")
            try await self.expectFirstMessage("200 Ok")
            
            reset()
        } catch {
            self.statusError = method.contains("97") ? UnitouchError.vivaWalletReceived : error  as! UnitouchError
        }
    }
    
    func cancelPayment() async {
        do {
            self.sendMessage(message: "ACCCLOSE")
            try await self.expectFirstMessage("200 Ok")
        } catch {
            self.statusError = error as? UnitouchError
        }
        
        self.reset()
    }
    
    func getBill() async -> String {
        do {
            self.sendMessage(message: "GETBILL")
            try await self.expectFirstMessage("201 Ready")
            let lines = try await self.getUntilEnd()
            return lines.joined(separator: "\n")
        } catch {
            //statusError = error as? UnitouchError
            return "Geen rekening beschikbaar"
        }
    }
    
    
    //MARK: TABLE USAGE
    func enterTable() async {
        do {
            guard
                let table = activeTable,
                let subTable = activeSubTable
            else { throw UnitouchError.invalidConfiguration }
            self.activeItems = []
            
            self.sendMessage(message: "ACCGETALL 1 \(table)\(subTable)")
            
            let result = try await self.receiveFirstMessage()
            
            if(result == "401 Account Locked"){
                self.reset()
                throw UnitouchError.tableLocked
            }
            
            
            //Convert to items
            let lines = try await self.getUntilEnd()
            for line in lines {
                let fields = line.components(separatedBy: "\t")
                if(fields.count >= 10 && fields[6].contains(".")) { // There is a price
                    self.activeItems.append(NewItem(
                        user: Int(fields[0]) ?? -1,
                        plu: Int(fields[1]) ?? -1,
                        name: fields[2],
                        quantity: Int(fields[3]) ?? -1,
                        rang: Int(fields[4]) ?? -1,
                        unk1: "F",
                        price: Int(fields[6]) ?? -1, // TODO: Fix
                        comment: fields[7]=="T" ? true : false,
                        listPlace: Int(fields[10]) ?? -1
                    ) )
                }
                
            }
            self.appState = .tableOpen
        } catch {
            self.statusError = error as? UnitouchError
        }
    }
    
    func leaveTable(newItems: [NewItem], deletedItems: [NewItem]) async {
        do {
            guard
                let table = activeTable,
                let subTable = activeSubTable
            else { throw UnitouchError.invalidConfiguration }
            
            if newItems.isEmpty && deletedItems.isEmpty {
                self.sendMessage(message: "ACCCLOSE")
                try await self.expectFirstMessage("200 Ok")
            } else {
                self.sendMessage(message: "ACCPUT 1 \(table)\(subTable)")
                try await self.expectFirstMessage("201 Ready")
                
                var data = ""
                for item in newItems {
                    data += "\(item.user)\t\(item.plu)\t\(item.name)\t\(item.quantity)\t\(item.rang)\tF\t\(item.price)\t\(item.comment ? "T" : "F")\t\t0\t0\t0\t0\t0\t0\t0\tF\n"
                }
                for item in deletedItems {
                    data += "\(item.user)\t\(item.plu)\t\(item.name)\t\(item.quantity)\t\(item.rang)\tF\t\(item.price)\t\(item.comment ? "T" : "F")\tX\t0\t\(item.listPlace)\t0\t0\t0\t0\t0\tF\n"
                }
                data += "//END"
                
                print(data)
                self.sendMessage(message: data)
                
                try await self.expectFirstMessage("200 Ok")
            }
        } catch {
            self.statusError = error as? UnitouchError
        }
        
        reset()
        
    }
    
    func reset() {
        self.appState = .selection
        self.activeTable = nil
        self.activeSubTable = nil
        self.activeItems = []
        self.splitTables = []
    }
}
