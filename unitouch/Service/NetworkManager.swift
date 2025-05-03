//
//  NetworkManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import Foundation
import Network

class NetworkManager {
    private var connection: NWConnection;
    var recvQ: [String];
    var buffer = Data();
    let queue = DispatchQueue(label: "thread-save-recvQ")
    
    init(){
        connection = NWConnection(host: "192.168.101.66", port: 1026, using: .tcp)
        recvQ = []
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connected to server")
                self.receiveMessage()
            case .failed(let error):
                print("Connection failed: \(error)")
            default:
                print("Default case: \(state)")
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    func sendMessage(message: String, suffix: String = "\n") {
        let data = (message+suffix).data(using: .isoLatin1) ?? Data()
        self.connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                print("Message sent")
            }
        })
    }
    
    func onMessageReceived(_ message: String) {
        // Override point for subclasses
    }

    private func receiveMessage() {
        self.connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self.buffer.append(data)

                while let newlineRange = self.buffer.range(of: Data([0x0A])) { // '\n'
                    let lineData = self.buffer.subdata(in: 0..<newlineRange.lowerBound)
                    self.buffer.removeSubrange(0...newlineRange.lowerBound)

                    // Only decode after isolating a complete line
                    if let message = String(data: lineData, encoding: .isoLatin1) {
                        //print("✅ Received message: \(message)")
                        self.appendToRecvQ(message)
                        self.onMessageReceived(message)
                    } else {
                        print("❌ Invalid UTF-8 line (likely split multibyte character)")
                        print("Raw bytes: \(lineData.map { String(format: "%02x", $0) }.joined(separator: " "))")
                        // Keep buffer intact — we don’t throw away the rest
                    }
                }
            }
            
//            if let data = data, !data.isEmpty {
//                self.buffer.append(data)
//                
//                while true {
//                    // Attempt to convert as much of the buffer as possible into a valid UTF-8 string
//                    let fullString = String(decoding: self.buffer, as: UTF8.self)
//                    
//                    // Look for newline-delimited messages
//                    guard let newlineRange = fullString.range(of: "\n") else {
//                        break // no full line available yet
//                    }
//                    
//                    // Extract full line up to newline (excluding newline)
//                    let line = String(fullString[..<newlineRange.lowerBound])
//                    
//                    // Convert back to bytes to remove the correct range from buffer
//                    let lineByteCount = line.data(using: .utf8)?.count ?? 0
//                    let newlineByteCount = "\n".data(using: .utf8)?.count ?? 1
//                    
//                    // Remove the used bytes from buffer
//                    self.buffer.removeFirst(lineByteCount + newlineByteCount)
//                    
//                    // Send it into the queue
//                    self.queue.async{
//                        self.appendToRecvQ(line)
//                        self.onMessageReceived(line)
//                    }
//                }
//            }
            
            if isComplete {
                print("Connection closed by server")
                self.connection.cancel()
            } else if let error = error {
                print("Error receiving data: \(error)")
            } else {
                // Continue receiving
                self.receiveMessage()
            }
        }
    }
    
    
    func appendToRecvQ(_ message: String) {
        queue.async {
            self.recvQ.append(message)
        }
    }

    func getRecvQCount() -> Int {
        return queue.sync {
            self.recvQ.count
        }
    }

    func popMessage() -> String? {
        return queue.sync {
            guard !self.recvQ.isEmpty else { return nil }
            return self.recvQ.removeFirst()
        }
    }

    func removeAllRecvQ() {
        queue.async {
            self.recvQ.removeAll()
        }
    }
}



