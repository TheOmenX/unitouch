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

enum RequestType {
    case standard   // Expects: Command -> Response
    case download   // Expects: Command -> 201 -> Content -> //END
    case upload     // Expects: Command -> 201 -> Client Sends Data -> Response
}

enum ServerResponse {
    case success(code: Int, message: String)
    case content(data: String)
    case error(Error)
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed(Error)
}

// 1. New struct to hold queued requests
struct TCPRequest {
    let command: String
    let payload: String? // For uploads
    let type: RequestType
    let completion: (ServerResponse) -> Void
}

// MARK: - TCP Client
class TCPClient: ObservableObject { // Changed to ObservableObject for SwiftUI compatibility
    
    @MainActor static let shared = TCPClient()
    
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Configuration
    private let host = "unitouch.tijngiesberts.nl"
    private let port: UInt16 = 1026
    
    // MARK: - Private Properties
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.tijngiesberts.unitouch")
    
    // Buffering & State Machine
    private var buffer = Data()
    private var isReadingContent = false
    private var contentBuffer = ""
    
    // Request State
    private var activeRequestType: RequestType = .standard
    private var currentCompletion: ((ServerResponse) -> Void)?
    private var pendingUploadPayload: String?
    
    // 2. Queueing System
    private var requestQueue: [TCPRequest] = []
    private var isProcessing = false
    
    // Background Task Support
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var isIntentionalDisconnect = false
    private var isReconnecting = false

    // MARK: - Initialization
    private init() {
        registerBackgroundHandling()
    }
    
    // MARK: - Public API
    
    func start() {
        // Prevent multiple start calls
        if connection?.state == .ready || connection?.state == .preparing { return }

        print("🔌 TCP: Attempting connection to \(host):\(port)")
        DispatchQueue.main.async { self.connectionStatus = .connecting }
        isIntentionalDisconnect = false
        
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!
        
        connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleStateChange(state: state)
        }
        
        connection?.start(queue: queue)
    }
    
    func stop() {
        isIntentionalDisconnect = true
        connection?.cancel()
        print("🔌 TCP: Stopped intentionally.")
        DispatchQueue.main.async { self.connectionStatus = .disconnected }
    }
    
    // MARK: - Enqueueing Logic
    
    func sendCommand(_ command: String, type: RequestType = .standard, completion: @escaping (ServerResponse) -> Void) {
        queue.async {
            // Create request object
            let request = TCPRequest(command: command, payload: nil, type: type, completion: completion)
            
            // Add to queue
            self.requestQueue.append(request)
            
            // Try to process
            self.processNextRequest()
        }
    }
    
    func sendUploadCommand(_ command: String, payload: String, completion: @escaping (ServerResponse) -> Void) {
        queue.async {
            let request = TCPRequest(command: command, payload: payload, type: .upload, completion: completion)
            self.requestQueue.append(request)
            self.processNextRequest()
        }
    }
    
    // 3. The Processor
    private func processNextRequest() {
        // If we are already busy, or no requests left, or not connected, stop.
        guard !isProcessing, !requestQueue.isEmpty else { return }
        
        // Check connection state
        guard connection?.state == .ready else {
            print("⚠️ TCP: Cannot process request, socket not ready.")
            return
        }
        
        isProcessing = true
        let request = requestQueue.removeFirst()
        
        // Setup state for this specific request
        self.activeRequestType = request.type
        self.currentCompletion = request.completion
        self.isReadingContent = false // Reset parser state
        self.contentBuffer = ""
        
        // Handle upload specifics
        if request.type == .upload, let payload = request.payload {
            self.pendingUploadPayload = self.ensureNewline(payload) + "//END\n"
        }
        
        // Send the command
        self.send(data: self.ensureNewline(request.command))
    }
    
    // MARK: - Internal Network Logic
    
    private func send(data: String) {
        guard let content = data.data(using: .windowsCP1252) else { return }
        
        connection?.send(content: content, completion: .contentProcessed({ [weak self] error in
            if let error = error {
                print("❌ TCP Send Error: \(error)")
                self?.dispatchError(error)
            } else {
                print("📤 TCP: Sent \(data.trimmingCharacters(in: .newlines))")
            }
        }))
    }
    
    private func receive() {
        guard connection?.state == .ready else { return }

        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, context, isComplete, error) in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                self.buffer.append(data)
                self.processBuffer()
            }
            
            if let error = error {
                if case NWError.posix(let code) = error, code == .ECANCELED { return }
                print("❌ TCP Receive Error: \(error)")
                self.dispatchError(error) // Fail the current request
                self.connection?.cancel()
                return
            }
            
            if isComplete {
                print("⚠️ TCP: Server closed connection.")
                self.connection?.cancel()
                return
            }
            
            self.receive()
        }
    }
    
    private func handleStateChange(state: NWConnection.State) {
        DispatchQueue.main.async {
            switch state {
            case .ready:
                print("✅ TCP: Connected")
                self.connectionStatus = .connected
                self.isReconnecting = false
                // Start receiving logic now that we are ready
                self.queue.async {
                    self.receive()
                    // If requests piled up while connecting, process them now
                    // self.processNextRequest()
                }
                
            case .failed(let error):
                print("❌ TCP: Connection failed: \(error)")
                self.connectionStatus = .failed(error)
                self.attemptReconnect()
                
            case .cancelled:
                if !self.isIntentionalDisconnect {
                    self.connectionStatus = .disconnected
                    self.attemptReconnect()
                } else {
                    self.connectionStatus = .disconnected
                }
                
            case .waiting(let error):
                print("⏳ TCP: Waiting... \(error)")
                self.connectionStatus = .connecting
                
            default:
                break
            }
        }
    }
    
    private func attemptReconnect() {
        // Reset processing flag so queue halts
        queue.async { self.isProcessing = false }
        
        guard !isIntentionalDisconnect, !isReconnecting else { return }
        
        isReconnecting = true
        let delay = 2.0
        print("🔄 TCP: Reconnecting in \(delay)s...")
        
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.start()
        }
    }
    
    // MARK: - Protocol Parsing
    
    private func processBuffer() {
        while let range = buffer.range(of: Data("\n".utf8)) {
            let lineData = buffer.subdata(in: 0..<range.lowerBound)
            buffer.removeSubrange(0..<range.upperBound)
            
            if let lineString = String(data: lineData, encoding: .windowsCP1252) {
                handleLine(lineString.trimmingCharacters(in: .newlines))
            }
        }
    }
    
    private func handleLine(_ line: String) {
        if line.contains("100 Welcome") {
            print("📥 TCP: Received Welcome Message.")
            self.processNextRequest()
            return
        }
        
        
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
        
        let components = line.contains("\t") ? line.split(separator: "\t", maxSplits: 1).map(String.init) : line.split(separator: " ", maxSplits: 1).map(String.init)
        guard let codeString = components.first, let code = Int(codeString) else {
            // Ignore malformed lines if needed, or handle as error
            return
        }
        
        let message = components.count > 1 ? components[1] : ""
        
        if code == 201 {
            if activeRequestType == .download {
                isReadingContent = true
                contentBuffer = ""
            }
            else if activeRequestType == .upload {
                if let payload = pendingUploadPayload {
                    print("📤 TCP: Sending Upload Payload...")
                    send(data: payload)
                    pendingUploadPayload = nil
                }
            } else {
                dispatchSuccess(code: code, message: message)
            }
        } else {
            dispatchSuccess(code: code, message: message)
        }
    }
    
    // MARK: - Dispatch & Queue Management
    
    private func ensureNewline(_ str: String) -> String {
        return str.hasSuffix("\n") ? str : str + "\n"
    }
    
    private func dispatchSuccess(code: Int, message: String, dataPayload: String? = nil) {
        // 1. Capture completion to main thread
        let completionToCall = self.currentCompletion
        
        DispatchQueue.main.async {
            if let data = dataPayload {
                completionToCall?(.content(data: data))
            } else {
                completionToCall?(.success(code: code, message: message))
            }
        }
        
        // 2. Clear current request and start next
        finishCurrentRequest()
    }
    
    private func dispatchError(_ error: Error) {
        let completionToCall = self.currentCompletion
        
        DispatchQueue.main.async {
            completionToCall?(.error(error))
        }
        
        finishCurrentRequest()
    }
    
    // 4. Mark done and trigger next
    private func finishCurrentRequest() {
        self.isProcessing = false
        self.currentCompletion = nil
        self.activeRequestType = .standard // reset default
        
        // Process next item in queue immediately
        self.processNextRequest()
    }
}

// MARK: - Background Task Handling

extension TCPClient {
    private func registerBackgroundHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 App Backgrounded.")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("⏰ Background time expired.")
            self?.stop()
            self?.endBackgroundTask()
        }
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 App Foregrounded.")
        endBackgroundTask()
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
