//
//  TCPClient.swift
//  unitouch
//
//  Created by Tijn Giesberts on 26/01/2026.
//

import Foundation
import Network
import UIKit

// MARK: - Enums & Models

/// Represents the specific behavior expected for a request
enum RequestType {
    case standard   // Expects: Command -> Response (Case 1)
    case download   // Expects: Command -> 201 -> Content -> //END (Case 2)
    case upload     // Expects: Command -> 201 -> Client Sends Data -> Response (Case 3)
}

/// The result returned to the UI
enum ServerResponse {
    case success(code: Int, message: String) // Standard response (e.g. "200 OK")
    case content(data: String)               // Bulk data response (The text between 201 and //END)
    case error(Error)                        // Connection or System errors
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed(Error)
}

// MARK: - TCP Client
class TCPClient {
    
    // Singleton Instance
    @MainActor static let shared = TCPClient()
    
    //
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Configuration
    private let host = "unitouch.tijngiesberts.nl" // REPLACE with your server IP
    private let port: UInt16 = 1026   // REPLACE with your server Port
    
    // MARK: - Private Properties
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.tijngiesberts.unitouch")
    
    // Buffering & State Machine
    private var buffer = Data()
    private var isReadingContent = false     // True if we are inside a "201...//END" block
    private var contentBuffer = ""           // Accumulates multi-line data
    
    // Request State
    private var activeRequestType: RequestType = .standard
    private var currentCompletion: ((ServerResponse) -> Void)?
    
    // Temporary storage for Uploads (Case 3)
    private var pendingUploadPayload: String?
    
    // Background Task Support
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var isIntentionalDisconnect = false
    private var isReconnecting = false

    // MARK: - Initialization
    private init() {
        registerBackgroundHandling()
    }
    
    // MARK: - Public API
    
    /// Start the TCP connection and listen for updates
    func start() {
        print("🔌 TCP: Attempting connection to \(host):\(port)")
        isIntentionalDisconnect = false
        
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!
        
        // Use .tcp (add .tls here if you need SSL)
        connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleStateChange(state: state)
        }
        
        connection?.start(queue: queue)
    }
    
    /// Stop the connection manually (e.g. user logout)
    func stop() {
        isIntentionalDisconnect = true
        connection?.cancel()
        print("🔌 TCP: Stopped intentionally.")
    }
    
    /// Case 1 & 2: Send a command and wait for response or data
    /// - Parameters:
    ///   - command: The command string (e.g. "GET_TABLE 5")
    ///   - type: .standard (default) or .download if you expect bulk data
    func sendCommand(_ command: String, type: RequestType = .standard, completion: @escaping (ServerResponse) -> Void) {
        queue.async {
            self.activeRequestType = type
            self.currentCompletion = completion
            self.send(data: self.ensureNewline(command))
        }
    }
    
    /// Case 3: Upload flow. Sends command -> Waits for 201 -> Sends Payload -> Waits for 200
    func sendUploadCommand(_ command: String, payload: String, completion: @escaping (ServerResponse) -> Void) {
        queue.async {
            self.activeRequestType = .upload
            self.currentCompletion = completion
            self.pendingUploadPayload = self.ensureNewline(payload) + "//END\n"
            
            // Send the initial command to trigger the "201 Ready"
            self.send(data: self.ensureNewline(command))
        }
    }
    
    // MARK: - Internal Network Logic
    
    private func send(data: String) {
        guard let content = data.data(using: .utf8) else { return }
        
        connection?.send(content: content, completion: .contentProcessed({ error in
            if let error = error {
                print("❌ TCP Send Error: \(error)")
                self.dispatchError(error)
            }
        }))
    }
    
    private func receive() {
        // Read available bytes
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, _, error) in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                self.buffer.append(data)
                self.processBuffer()
            }
            
            if let error = error {
                // If it's just "cancelled", ignore it. Otherwise report.
                if case NWError.posix(let code) = error, code == .ECANCELED {
                    return
                }
                print("❌ TCP Receive Error: \(error)")
                self.connection?.cancel() // This will trigger stateUpdateHandler -> failed
            } else {
                // Continue reading endlessly
                self.receive()
            }
        }
    }
    
    private func handleStateChange(state: NWConnection.State) {
        switch state {
        case .ready:
            print("✅ TCP: Connected")
            isReconnecting = false
            receive() // Start the read loop
            
        case .failed(let error):
            print("❌ TCP: Connection failed: \(error)")
            attemptReconnect()
            
        case .cancelled:
            if !isIntentionalDisconnect {
                print("⚠️ TCP: Connection cancelled unexpectedly.")
                attemptReconnect()
            }
            
        case .waiting(let error):
            print("⏳ TCP: Waiting (Network change?): \(error)")
            
        default:
            break
        }
    }
    
    private func attemptReconnect() {
        guard !isIntentionalDisconnect, !isReconnecting else { return }
        
        isReconnecting = true
        let delay = 2.0
        print("🔄 TCP: Reconnecting in \(delay)s...")
        
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.start()
        }
    }
    
    // MARK: - Protocol Parsing (The State Machine)
    
    private func processBuffer() {
        // Extract lines ending with \n
        while let range = buffer.range(of: Data("\n".utf8)) {
            let lineData = buffer.subdata(in: 0..<range.lowerBound)
            buffer.removeSubrange(0..<range.upperBound)
            
            if let lineString = String(data: lineData, encoding: .utf8) {
                handleLine(lineString.trimmingCharacters(in: .newlines))
            }
        }
    }
    
    private func handleLine(_ line: String) {
        // MODE A: Accumulating Content (Case 2)
        if isReadingContent {
            if line == "//END" {
                isReadingContent = false
                let finalContent = contentBuffer
                contentBuffer = ""
                dispatchSuccess(code: 200, message: "Download Complete", dataPayload: finalContent)
            } else {
                contentBuffer += line + "\n"
            }
            return
        }
        
        // MODE B: Parsing Commands/Status Codes
        let components = line.split(separator: " ", maxSplits: 1).map(String.init)
        guard let codeString = components.first, let code = Int(codeString) else {
            print("⚠️ Protocol Error: Unknown format '\(line)'")
            return
        }
        
        let message = components.count > 1 ? components[1] : ""
        
        // Handle "201 Ready"
        if code == 201 {
            if activeRequestType == .download {
                // Case 2: Server is about to send content. Switch modes.
                isReadingContent = true
                contentBuffer = ""
            }
            else if activeRequestType == .upload {
                // Case 3: Server is ready for our payload. Send it automatically.
                if let payload = pendingUploadPayload {
                    print("📤 TCP: Sending Upload Payload...")
                    send(data: payload)
                    pendingUploadPayload = nil
                }
            } else {
                // Standard command returned 201? Treat as success.
                dispatchSuccess(code: code, message: message)
            }
        } else {
            // Standard Response (200, 400, 500, etc.)
            dispatchSuccess(code: code, message: message)
        }
    }
    
    // MARK: - Helpers
    private func ensureNewline(_ str: String) -> String {
        return str.hasSuffix("\n") ? str : str + "\n"
    }
    
    private func dispatchSuccess(code: Int, message: String, dataPayload: String? = nil) {
        DispatchQueue.main.async {
            if let data = dataPayload {
                self.currentCompletion?(.content(data: data))
            } else {
                self.currentCompletion?(.success(code: code, message: message))
            }
        }
    }
    
    private func dispatchError(_ error: Error) {
        DispatchQueue.main.async {
            self.currentCompletion?(.error(error))
        }
    }
}

// MARK: - Background Task Handling

extension TCPClient {
    
    private func registerBackgroundHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 App Backgrounded. Requesting TCP persistence...")
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("⏰ Background time expired. Cutting connection.")
            self?.stop()
            self?.endBackgroundTask()
        }
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 App Foregrounded.")
        endBackgroundTask()
        
        // If connection dropped, restart
        if connection?.state != .ready && connection?.state != .preparing {
            start()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

