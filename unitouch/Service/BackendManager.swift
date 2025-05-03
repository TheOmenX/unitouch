//
//  BackendManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//


enum BackendError: Error {
    case unexpectedResult(String)
}

import Foundation
class BackendManager: NetworkManager, ObservableObject {
    static let shared = BackendManager()
    
    private let semaphore = DispatchSemaphore(value: 0)
    @Published var activeTable: Int? = nil
    @Published var activeItems: [NewItem] = []
    
    var items: [Item] = []
    var categories: [Category] = []
    var temp_cat: [Int] = []
    
    override private init(){
        //TODO: Data storage and get timestamp
        super.init()
        
        self.sendMessage(message: "SETUSR 4 5")
        
        // WELCOME MESSAGE
        _ = semaphore.wait(timeout: .now() + 5) // timeout optional
        self.removeAllRecvQ()
        
        // ACTUAL OK MESSAGE
        do{
            try self.expectQ(exp: "200 Ok")
        } catch {
            print("ERROR")
        }
    
        
        // MARK: GET ALL CATEGORIES
        self.sendMessage(message: "DATAGET TYPES.txt")
        do{
            try self.expectQ(exp: "201 Ready")
        } catch {
            print("ERROR")
        }
        
        print("Getting categories")
        let categoryData = self.getUntilEnd()
        for line in categoryData {
            let fields = line.components(separatedBy: "\t")
            if(fields.count == 2) { // There is a price
                categories.append(Category(
                    id: Int(fields[0]) ?? -1,
                    name: fields[1]
                ) )
            }
        }
        
        
        
        // MARK: GET ALL ITEMS
        self.sendMessage(message: "DATAGET ART.txt")
        do{
            try self.expectQ(exp: "201 Ready")
        } catch {
            print("ERROR")
        }
        
        
        let itemData = self.getUntilEnd()
        for line in itemData {
            let fields = line.components(separatedBy: "\t")
            
            if(fields.count >= 10 && fields[3].contains(".")) { // There is a price
                items.append(Item(
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
                
                if(!self.temp_cat.contains(Int(fields[2]) ?? -1)){
                    self.temp_cat.append(Int(fields[2]) ?? -1)
                }
            }
        }
        
        
        
        //MARK: Convert all GRP to correct numbers
        for (index, value) in (temp_cat.sorted()).enumerated() {
            if index == value {continue}
            for (index1, _) in items.enumerated() {
                if(items[index1].page == value){
                    items[index1].page = index
                }
            }
        }
        
        items.sort { $0.unk4 < $1.unk4 }
    }
    
    override func onMessageReceived(_ message: String) {
        super.onMessageReceived(message)
        semaphore.signal()
    }
    
    func expectQ(exp: String) throws {
        _ = semaphore.wait(timeout: .now() + 5)
        let res = queue.sync {
            return recvQ.first
        }

        guard let res else {
            print("No data was recieved")
            throw BackendError.unexpectedResult("No data received")
        }
        
        queue.async {
            self.recvQ.removeFirst()
        }
        
        
        if(res != exp){
            print("Not result as expected. Expected \(exp) - Received \(res)")
            throw BackendError.unexpectedResult("Incorrect data received")
        }
    }
    
    
    func openTable(table: Int) -> Bool {
        self.sendMessage(message: "ACCGETALL 1 \(table)0")
        do {
            try self.expectQ(exp: "201 Ready")
            self.activeTable = table
        } catch {
            print("Couldn't open table")
            return false
        }
        
        //Convert to items
        let lines = self.getUntilEnd()
        for line in lines {
            let fields = line.components(separatedBy: "\t")
            
            
            if(fields.count >= 10 && fields[6].contains(".")) { // There is a price
                self.activeItems.append(NewItem(
                    user: Int(fields[0]) ?? -1,
                    plu: Int(fields[1]) ?? -1,
                    name: fields[2],
                    quantity: 1,
                    rang: Int(fields[4]) ?? -1,
                    unk1: "F",
                    price: Int(fields[6]) ?? -1, // TODO: Fix
                    comment: fields[7]=="T" ? true : false,
                    listPlace: Int(fields[10]) ?? -1
                ) )
            }
            
        }

        print(self.activeItems)
        
        return true
    }
    
    func leaveTable(newItems: [NewItem], deletedItems: [NewItem]) {
        if newItems.isEmpty && deletedItems.isEmpty {
            self.sendMessage(message: "ACCCLOSE")
            do {
                try self.expectQ(exp: "200 Ok")
            } catch {
                print("Error leaving table")
            }
        } else {
            self.sendMessage(message: "ACCPUT 1 \(self.activeTable ?? -1)0")
            do {
                try self.expectQ(exp: "201 Ready")
            } catch {
                print("Error leaving table")
            }
            
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
            
            do {
                try self.expectQ(exp: "200 OK")
            } catch {
                print("Error leaving table")
            }
        }
        
        self.activeTable = nil
        self.activeItems = []
        
        self.removeAllRecvQ()
    }
    
    
    private func getUntilEnd() -> [String]{
        var value: [String] = []
        while true {
            _ = semaphore.wait(timeout: .now() + 5)
            guard let message = popMessage() else { break }
            
            value.append(message)
            
            if(message.contains("//END")) { break }
        }
        
        return value
    }
}
