//
//  Errors.swift
//  unitouch
//
//  Created by Tijn Giesberts on 8/5/25.
//

import SwiftUI

enum UnitouchError: Error, Identifiable {
    case invalidPassword
    case tableNotEmpty
    case tableLocked
    case tableEmpty
    case sendFailed
    case streamEnded
    case timeout

    case noDataRecieved
    
    case noBlockedItemsReceived
    case itemBlocked
    case invalidBlockedItemQuantity
    
    case vivaWalletError
    case invalidVivaWalletURL
    case openingVivaWalletFailed
    case vivaPaymentProcessingError(message: String)
    case vivaBalanceMismatch(expected: Double, received: Double)
    
    case unknown(err: String)
    
    var id: String {
        switch self {
        case .invalidPassword: return "invalidPassword"
        case .tableNotEmpty: return "tableNotEmpty"
        case .tableLocked: return "tableLocked"
        case .tableEmpty: return "tableEmpty"
        case .sendFailed: return "sendFailed"
        case .streamEnded: return "streamEnded"
        case .timeout: return "timeout"

        case .noDataRecieved: return "noDataRecieved"
            
        case .noBlockedItemsReceived: return "noBlockedItemReceived"
        case .itemBlocked: return "itemBlocked"
        case .invalidBlockedItemQuantity: return "invalidBlockedItemQuantity"
            
        case .vivaWalletError: return "vivaWalletError"
        case .invalidVivaWalletURL: return "invalidVivaWalletURL"
        case .openingVivaWalletFailed: return "openingVivaWalletFailed"
        case .vivaPaymentProcessingError: return "vivaPaymentProcessingError"
        case .vivaBalanceMismatch: return "vivaBalanceMismatch"
            
        case .unknown(let err): return "unknown:\(err)"
        }
    }
    
    var message: String {
        switch self {
        case .invalidPassword:
            return "Ongeldig wachtwoord ingevoerd."
        case .tableNotEmpty:
            return "De tafel is niet leeg. Wilt u de tafel verplaatsen?"
        case .tableLocked:
            return "De tafel is momenteel in gebruik. Probeer later opnieuw."
        case .tableEmpty:
            return "Er is geen bestelling in de tafel."
        case .sendFailed:
            return "Kon bericht niet sturen naar de kassa."
        case .streamEnded:
            return "De stream is onverwacht beëindigd."
        case .timeout:
            return "De verbinding is verlopen."

        case .noDataRecieved:
            return "De server heeft geen data teruggestuurd."
            
        case .noBlockedItemsReceived:
            return "Er zijn geen geblokkeerde items te verwijderen."
        case .itemBlocked:
            return "Dit item is geblokkeerd en kan niet worden aangepast."
        case .invalidBlockedItemQuantity:
            return "De hoeveelheid van een geblokkeerd item kan niet worden aangepast. Probeer het opnieuw."
            
        case .vivaWalletError:
            return "Viva Wallet heeft een foutmelding teruggestuurd."
        case .invalidVivaWalletURL:
            return "Er ging iets mis bij het klaarzetten van de link naar Viva Wallet."
        case .openingVivaWalletFailed:
            return "De Viva Wallet app kon niet geopend worden. Zorg ervoor dat deze is geïnstalleerd op het apparaat."
        case .vivaPaymentProcessingError(let message):
            return "LET OP: Er is een fout opgetreden tijdens het verwerken van de betaling. De betaling is WEL ontvangen: \(message)"
        case .vivaBalanceMismatch(let expected, let received):
            return "LET OP: Het ontvangen bedrag komt niet overeen met het verwachte bedrag. Verwacht: €\(String(format: "%.2f", expected)), Ontvangen: €\(String(format: "%.2f", received)). De tafel is NIET afgerekend."
            
        case .unknown(let err):
            return "Onbekende fout: \(err)"
        }
    }
}
