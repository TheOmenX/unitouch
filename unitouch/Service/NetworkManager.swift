//
//  NetworkManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import Foundation
import Network



@Observable class NetworkManager {
    @MainActor var connectionState: ConnectionState = .ready
    var connection: NWConnection;
    var retries = 0;
    private var buffer = Data();
    private var sharedStream: AsyncStream<String>?
    private var messageStream: AsyncStream<String>.Continuation?

    
    init(){
        self.connection = NetworkManager.createConnection()
        self.setupConnection()
        self.initializeSharedStream()
    }

    private func initializeSharedStream() {
        self.sharedStream = AsyncStream<String> { continuation in
            self.messageStream = continuation
        }
    }
    
    static func createConnection() -> NWConnection {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 10
        tcpOptions.keepaliveCount = 2
        tcpOptions.keepaliveInterval = 2
        tcpOptions.connectionTimeout = 5

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.prohibitConstrainedPaths = false
        parameters.prohibitExpensivePaths = false
        
        return NWConnection(host: "unitouch.tijngiesberts.nl", port: 80, using: parameters)
        //return NWConnection(host: "192.168.101.66", port: 1026, using: parameters)
    }
        
    func setupConnection() {
        connection.stateUpdateHandler  = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .ready:
                print("Connected to server!")
                retries = 0;
                self.receiveMessage()
                Task { @MainActor in
                    //try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
                    await self.setup(reconnect: (self.connectionState == .reconnecting))
                }
            case .waiting(let error):
                print("Connection waiting (likely temporary issue): \(error)")
                self.reconnect()
            case .failed(let error):
                print("Connection failed: \(error)")
                self.reconnect()
            case .cancelled:
                print("Connection cancelled")
            default:
                print("Other state: \(state)")
            }
        }
        
        connection.start(queue: .global())
    }
    
    func reconnect() {
        self.connection.cancel() // Clean up the old connection
        
        if self.retries > 5 {
            Task { @MainActor in self.connectionState = .lost }
            return
        }
        Task { @MainActor in self.connectionState = .reconnecting }

        
        let delay = retries == 0 ? 0.0 : 5.0
        self.retries += 1;
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            print("Reconnecting...")
            self.connection = NetworkManager.createConnection()
            self.setupConnection()
        }
    }
    
    
    func sendMessage(message: String, suffix: String = "\n") {
        let data = (message+suffix).data(using: .windowsCP1252) ?? Data()
        self.connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                print("📤 Message sent: \(message)")
            }
        })
    }
    
    func setup(reconnect: Bool) async {
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
                    if let message = String(data: lineData, encoding: .windowsCP1252) {
                        self.messageStream?.yield(message)
                        print("✅ Received message: \(message)")
                    } else {
                        print("❌ Invalid line (likely split multibyte character)")
                        print("Raw bytes: \(lineData.map { String(format: "%02x", $0) }.joined(separator: " "))")
                        // Keep buffer intact — we don’t throw away the rest
                    }
                }
            }
            
            if isComplete {
                print("Connection closed by server")
                self.connection.cancel()
                Task { @MainActor in self.connectionState = .lost}
            } else if let error = error {
                print("Error receiving data: \(error)")
            } else {
                self.receiveMessage()
            }
        }
    }

    func receiveFirstMessage(timeout seconds: TimeInterval = 5) async throws -> String? {
        guard let stream = sharedStream else { throw UnitouchError.streamEnded }

        return try await withThrowingTaskGroup(of: String?.self) { group in
            // Task to wait for the first message
            group.addTask {
                for await message in stream {
                    return message // Return the first message
                }
                throw UnitouchError.streamEnded
            }

            // Task for the timeout
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                self.reconnect()
                throw UnitouchError.timeout
            }

            // Return the first task that finishes
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    func expectFirstMessage(_ expected: String) async throws {
        let message = try await receiveFirstMessage()
        if message != expected {
            // Reset the stream if an unexpectedMessage occured
            throw UnitouchError.unexpectedMessage(exp: expected, rec: message ?? "")
        }
    }
    
    func getUntilEnd() async throws -> [String] {
        guard let stream = sharedStream else { throw UnitouchError.streamEnded }
        
        var messages: [String] = []
        

        // Process messages until we see the end marker
        for await message in stream {
            if message.contains("//END") {
                return messages
            }
            messages.append(message)
        }
        
        throw UnitouchError.missingEndMarker
    }

    // --- Add this cleanup method ---
    func cleanup() {
        print("Cleaning up NetworkManager: Cancelling NWConnection")
        connection.cancel()
    }
}
