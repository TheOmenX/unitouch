//
//  Errors.swift
//  unitouch
//
//  Created by Tijn Giesberts on 8/5/25.
//

import SwiftUI

enum UnitouchError: Error, Identifiable {
    case invalidPassword
    case tableNotEmpty(action: (() -> Void)? = nil)
    case invalidConfiguration
    case tableLocked
    case tableEmpty
    case vivaWalletReceived
    case invalidVivaWalletURL
    case openingVivaWalletFailed
    case sendFailed
    case streamEnded
    case timeout
    case unexpectedMessage(exp: String, rec: String)
    case missingEndMarker
    case noDataRecieved
    case unknown(err: String)
    
    var id: String {
        switch self {
        case .invalidPassword: return "invalidPassword"
        case .tableNotEmpty: return "tableNotEmpty"
        case .invalidConfiguration: return "invalidConfiguration"
        case .tableLocked: return "tableLocked"
        case .tableEmpty: return "tableEmpty"
        case .vivaWalletReceived: return "vivaWalletReceived"
        case .invalidVivaWalletURL: return "invalidVivaWalletURL"
        case .openingVivaWalletFailed: return "openingVivaWalletFailed"
        case .sendFailed: return "sendFailed"
        case .streamEnded: return "streamEnded"
        case .timeout: return "timeout"
        case .unexpectedMessage(let exp, let rec): return "unexpectedMessage:\(exp):\(rec)"
        case .missingEndMarker: return "missingEndMarker"
        case .noDataRecieved: return "noDataRecieved"
        case .unknown(let err): return "unknown:\(err)"
        }
    }
    
    var message: String {
        switch self {
        case .invalidPassword:
            return "Ongeldig wachtwoord ingevoerd."
        case .tableNotEmpty:
            return "De tafel is niet leeg. Wilt u de tafel verplaatsen?"
        case .invalidConfiguration:
            return "Er is een fout opgetreden bij het ophalen van de configuratie."
        case .tableLocked:
            return "De tafel is momenteel in gebruik. Probeer later opnieuw."
        case .tableEmpty:
            return "Er is geen bestelling in de tafel."
        case .vivaWalletReceived:
            return "Viva Wallet heeft een foutmelding teruggestuurd."
        case .invalidVivaWalletURL:
            return "Er ging iets mis bij het klaarzetten van de link naar Viva Wallet."
        case .openingVivaWalletFailed:
            return "De Viva Wallet app kon niet geopend worden. Zorg ervoor dat deze is geïnstalleerd op het apparaat."
        case .sendFailed:
            return "Kon bericht niet sturen naar de kassa."
        case .streamEnded:
            return "De stream is onverwacht beëindigd."
        case .timeout:
            return "De verbinding is verlopen."
        case .unexpectedMessage(let exp, let rec):
            return "Verwachtte bericht: \(exp), maar kreeg: \(rec)"
        case .missingEndMarker:
            return "Ontbrekende eindmarker in de stream."
        case .noDataRecieved:
            return "De server heeft geen data teruggestuurd."
        case .unknown(let err):
            return "Onbekende fout: \(err)"
        }
    }
}
