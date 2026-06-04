//
//  Errors.swift
//  unitouch
//
//  Created by Tijn Giesberts on 8/5/25.
//

import SwiftUI

enum UnitouchError: Error, Identifiable {
    // Netwerk & Data
    case networkError(details: String)
    case dataSyncFailed(details: String)
    case invalidServerResponse(action: String, details: String)
    
    // Authenticatie
    case invalidPassword
    case userLoginFailed(details: String)
    
    // Tafel Statussen
    case noActiveTable
    case tableLocked
    case tableEmpty
    case tableNotEmpty
    
    // Tafel Acties
    case closeTableFailed(details: String)
    case fetchOpenTablesFailed(details: String)
    case checkSubTableFailed(details: String)
    case openTableFailed(details: String)
    case fetchNumberOfPeopleFailed(details: String)
    case setNumberOfPeopleFailed(details: String)
    case moveTableFailed(details: String)
    case splitTableFailed(details: String)
    case openTableMapFailed(details: String)
    
    // Items & Bestellingen
    case noBlockedItemsReceived
    case itemBlocked
    case invalidBlockedItemQuantity
    case addBlockedItemFailed(details: String)
    
    // Betalingen
    case fetchBillFailed(details: String)
    case paymentCompletionFailed(details: String)
    
    // Viva Wallet
    case vivaWalletError
    case invalidVivaWalletURL
    case openingVivaWalletFailed
    case vivaPaymentProcessingError(details: String)
    case vivaBalanceMismatch(expected: Double, received: Double)
    
    // Fallback
    case unknown(err: String)

    var id: String {
        switch self {
        case .networkError(let details): return "networkError_\(details)"
        case .dataSyncFailed(let details): return "dataSyncFailed_\(details)"
        case .invalidServerResponse(let action, let details): return "invalidServerResponse_\(action)_\(details)"
        
        case .invalidPassword: return "invalidPassword"
        case .userLoginFailed(let details): return "userLoginFailed_\(details)"
        
        case .noActiveTable: return "noActiveTable"
        case .tableLocked: return "tableLocked"
        case .tableEmpty: return "tableEmpty"
        case .tableNotEmpty: return "tableNotEmpty"
        
        case .closeTableFailed(let details): return "closeTableFailed_\(details)"
        case .fetchOpenTablesFailed(let details): return "fetchOpenTablesFailed_\(details)"
        case .checkSubTableFailed(let details): return "checkSubTableFailed_\(details)"
        case .openTableFailed(let details): return "openTableFailed_\(details)"
        case .fetchNumberOfPeopleFailed(let details): return "fetchNumberOfPeopleFailed_\(details)"
        case .setNumberOfPeopleFailed(let details): return "setNumberOfPeopleFailed_\(details)"
        case .moveTableFailed(let details): return "moveTableFailed_\(details)"
        case .splitTableFailed(let details): return "splitTableFailed_\(details)"
        case .openTableMapFailed(let details): return "openTableMapFailed_\(details)"
        
        case .noBlockedItemsReceived: return "noBlockedItemsReceived"
        case .itemBlocked: return "itemBlocked"
        case .invalidBlockedItemQuantity: return "invalidBlockedItemQuantity"
        case .addBlockedItemFailed(let details): return "addBlockedItemFailed_\(details)"
        
        case .fetchBillFailed(let details): return "fetchBillFailed_\(details)"
        case .paymentCompletionFailed(let details): return "paymentCompletionFailed_\(details)"
        
        case .vivaWalletError: return "vivaWalletError"
        case .invalidVivaWalletURL: return "invalidVivaWalletURL"
        case .openingVivaWalletFailed: return "openingVivaWalletFailed"
        case .vivaPaymentProcessingError(let details): return "vivaPaymentProcessingError_\(details)"
        case .vivaBalanceMismatch(let expected, let received): return "vivaBalanceMismatch_\(expected)_\(received)"
        
        case .unknown(let err): return "unknown_\(err)"
        }
    }

    var title: String {
        switch self {
        case .networkError: return "Netwerkfout"
        case .dataSyncFailed: return "Synchronisatiefout"
        case .invalidServerResponse: return "Ongeldige Server Response"
            
        case .invalidPassword: return "Ongeldig Wachtwoord"
        case .userLoginFailed: return "Aanmelden Mislukt"
            
        case .noActiveTable: return "Geen Tafel Geselecteerd"
        case .tableLocked: return "Tafel in Gebruik"
        case .tableEmpty: return "Tafel is Leeg"
        case .tableNotEmpty: return "Tafel Niet Leeg"
            
        case .closeTableFailed: return "Tafel Sluiten Mislukt"
        case .fetchOpenTablesFailed: return "Ophalen Open Tafels Mislukt"
        case .checkSubTableFailed: return "Controleren Subtafels Mislukt"
        case .openTableFailed: return "Tafel Openen Mislukt"
        case .fetchNumberOfPeopleFailed: return "Aantal Personen Ophalen Mislukt"
        case .setNumberOfPeopleFailed: return "Aantal Personen Instellen Mislukt"
        case .moveTableFailed: return "Tafel Verplaatsen Mislukt"
        case .splitTableFailed: return "Tafel Splitsen Mislukt"
        case .openTableMapFailed: return "Plattegrond Openen Mislukt"
            
        case .noBlockedItemsReceived: return "Geen Geblokkeerde Items"
        case .itemBlocked: return "Item Geblokkeerd"
        case .invalidBlockedItemQuantity: return "Ongeldige Hoeveelheid"
        case .addBlockedItemFailed: return "Item Blokkeren Mislukt"
            
        case .fetchBillFailed: return "Rekening Ophalen Mislukt"
        case .paymentCompletionFailed: return "Betaling Afronden Mislukt"
            
        case .vivaWalletError: return "Viva Wallet Fout"
        case .invalidVivaWalletURL: return "Ongeldige Betaallink"
        case .openingVivaWalletFailed: return "Viva Wallet Openen Mislukt"
        case .vivaPaymentProcessingError: return "Verwerkingsfout Betaling"
        case .vivaBalanceMismatch: return "Bedrag Komt Niet Overeen"
            
        case .unknown: return "Onbekende Fout"
        }
    }

    var description: String {
        switch self {
        case .networkError(let details):
            return "Er is een probleem met de netwerkverbinding: \(details)"
        case .dataSyncFailed(let details):
            return "Kon de data niet synchroniseren met de kassa: \(details)"
        case .invalidServerResponse(let action, let details):
            return "Er is een onverwachte response ontvangen bij actie '\(action)': \(details)"
            
        case .invalidPassword:
            return "Ongeldig wachtwoord ingevoerd. Probeer het opnieuw."
        case .userLoginFailed(let details):
            return "Er ging iets mis bij het aanmelden van de medewerker: \(details)"
            
        case .noActiveTable:
            return "Er is momenteel geen actieve tafel geselecteerd om deze actie uit te voeren."
        case .tableLocked:
            return "De geselecteerde tafel is momenteel in gebruik. Probeer het later opnieuw."
        case .tableEmpty:
            return "Er is geen bestelling op deze tafel."
        case .tableNotEmpty:
            return "De tafel is niet leeg. Wilt u de tafel eerst verplaatsen?"
            
        case .closeTableFailed(let details):
            return "Kon de tafel niet correct afsluiten: \(details)"
        case .fetchOpenTablesFailed(let details):
            return "Kon het overzicht van openstaande tafels niet ophalen: \(details)"
        case .checkSubTableFailed(let details):
            return "Kon de splitsing status van de tafel niet controleren: \(details)"
        case .openTableFailed(let details):
            return "Er ging iets mis bij het openen van de tafel: \(details)"
        case .fetchNumberOfPeopleFailed(let details):
            return "Kon het aantal personen voor deze tafel niet ophalen: \(details)"
        case .setNumberOfPeopleFailed(let details):
            return "Kon het aantal personen voor deze tafel niet opslaan: \(details)"
        case .moveTableFailed(let details):
            return "Er ging iets mis bij het verplaatsen van de tafel: \(details)"
        case .splitTableFailed(let details):
            return "Er ging iets mis bij het splitsen van de tafel: \(details)"
        case .openTableMapFailed(let details):
            return "Kon de tafel plattegrond niet inladen: \(details)"
            
        case .noBlockedItemsReceived:
            return "Er zijn geen geblokkeerde items gevonden of te verwijderen."
        case .itemBlocked:
            return "Dit item is geblokkeerd en kan op dit moment niet worden aangepast."
        case .invalidBlockedItemQuantity:
            return "De hoeveelheid van een geblokkeerd item kan niet worden aangepast. Probeer het opnieuw."
        case .addBlockedItemFailed(let details):
            return "Kon de blokkade voor het geselecteerde item niet toevoegen: \(details)"
            
        case .fetchBillFailed(let details):
            return "Kon het actuele bedrag of de rekening niet ophalen: \(details)"
        case .paymentCompletionFailed(let details):
            return "Er ging iets mis tijdens het verwerken of afronden van de betaling: \(details)"
            
        case .vivaWalletError:
            return "Viva Wallet heeft een foutmelding teruggestuurd. Controleer de terminal."
        case .invalidVivaWalletURL:
            return "Er ging iets mis bij het klaarzetten van de betaallink voor Viva Wallet."
        case .openingVivaWalletFailed:
            return "De Viva Wallet app kon niet geopend worden. Zorg ervoor dat deze correct is geïnstalleerd op het apparaat."
        case .vivaPaymentProcessingError(let details):
            return "LET OP: Er is een fout opgetreden tijdens het lokaal verwerken van de betaling. De betaling is WEL ontvangen door Viva Wallet: \(details)"
        case .vivaBalanceMismatch(let expected, let received):
            return "LET OP: Het betaalde bedrag komt niet overeen met het verwachtte bedrag. Verwacht: €\(String(format: "%.2f", expected)), Ontvangen: €\(String(format: "%.2f", received)). De tafel is NIET afgerekend."
            
        case .unknown(let err):
            return "Er is een onbekende fout opgetreden: \(err)"
        }
    }
}
