//
//  AuthenticationMiddleware.swift
//  unitouch
//
//  Created by Tijn Giesberts on 13/08/2026.
//


import Foundation
import OpenAPIRuntime
import HTTPTypes

// This middleware intercepts every outgoing API request and injects the header
struct AuthenticationMiddleware: ClientMiddleware {
    // A closure to fetch the current user ID dynamically
    var fetchUserId: () -> String?

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        
        var modifiedRequest = request
        
        // If we have an active user, inject the header!
        if let userId = fetchUserId() {
            modifiedRequest.headerFields[.init("X-User-ID")!] = userId
        }
        
        // Pass the modified request down the chain
        return try await next(modifiedRequest, body, baseURL)
    }
}