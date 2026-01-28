//
//  Errors.swift
//  unitouch
//
//  Created by Tijn Giesberts on 8/5/25.
//

import SwiftUI


// This is horrible
enum UnitouchState: Equatable {
    case setup          // When setting up the stuff
    case lost           // When the connection is lost
    
    case login          // When logging in
    case selection      // When selecting a table
    case tableOpen      // When table is open
    case payment        // When starting a payment
    case movingTable    // When moving a table
    indirect case splitTable(table: Int, for: UnitouchState) // When checking a table
}


enum UnitouchError: Error, Identifiable {
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
    case unknown(err: String)
    
    var id: String {
        switch self {
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
        case .unknown(let err): return "unknown:\(err)"
        }
    }
    
    var message: String {
        switch self {
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
        case .unknown(let err):
            return "Onbekende fout: \(err)"
        }
    }
}




/*
enum UnitouchPaymentStatus: Identifiable, Equatable {
    case idle
    case success
    case failed(message: String)
    case accountLocked
    case invalidURL
    case tableEmpty
    case missingInfo
    case launchFailed
    case unknown
    case invalidReturn
    case vivaWalletReceived
    
    var id: String {
        switch self {
        case .idle: return "idle"
        case .success: return "success"
        case .failed(let message): return "failed:\(message)"
        case .accountLocked: return "accountLocked"
        case .invalidURL: return "invalidURL"
        case .tableEmpty: return "tableEmpty"
        case .missingInfo: return "missingInfo"
        case .launchFailed: return "launchFailed"
        case .unknown: return "unknown"
        case .invalidReturn: return "invalidReturn"
        case .vivaWalletReceived: return "vivaWalletReceived"
        }
    }

    var alertContent: (title: String, message: String) {
        switch self {
        case .idle:
            return ("Betaling", "Er is geen betaling gestart.")
        case .success:
            return ("Betaling succesvol", "")
        case .failed(let message):
            return ("Betaling mislukt", message)
        case .accountLocked:
            return ("Tafel in gebruik", "De tafel is momenteel in gebruik. Probeer later opnieuw.")
        case .invalidURL:
            return ("Ongeldige link", "Er ging iets mis bij het klaarzetten van de link naar vivawallet.")
        case .tableEmpty:
            return ("Tafel leeg", "Er is geen bestelling in de tafel")
        case .missingInfo:
            return ("FUCKSHIT", "Holy shit what the fuck is going wrong fuck fuck idk whats happening.")
        case .launchFailed:
            return ("Kon viva wallet niet starten", "De viva wallet app kon niet geopend worden, zorg dat deze is geinstalleerd op het apparaat.")
        case .unknown:
            return ("Er ging iets mis", "Er is een onbekende fout opgetreden.")
        case .invalidReturn:
            return ("Ongeldige link", "Vivawallet stuurde een ongeldige link terug.")
        case .vivaWalletReceived:
            return ("Fout na betaling ontvangen", "Er is een fout bij het doorgeven naar de kassa opgetreden. Probeer de rekening later contant af te slaan!")
        }
    }
    
    var alert: Alert {
        let content = self.alertContent
        switch self {
        case .vivaWalletReceived:
            return Alert(
                title: Text(content.title),
                message: Text(content.message),
                primaryButton: .default(Text("Opniew proberen"), action: {
                    Task {
                        let result = await BackendManager.shared.finishPayment(method: "97\tViva Wallet")
                        
                        await MainActor.run {
                            if result != nil {
                                //BackendManager.shared.paymentStatus = .failed(message: "LET OP! Er is geld ontvangen maar de tafel kon niet afgerekend worden. Sla deze in de kassa of via de handheld contant af!")
                            }
                        }
                    }
                }),
                secondaryButton: .cancel(Text("Ok"))
            )
        default:
            return Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .default(Text("Ok"))
            )
        }
    }
}


enum UnitouchTableStatus: Identifiable {
    case accountLocked
    case tableEmpty
    case tableContainsItems
    
    var id: String {
        switch self {
        case .accountLocked: return "accountLocked"
        case .tableEmpty: return "tableEmpty"
        case .tableContainsItems: return "tableContainsItems"
        }
    }
    
    var alertContent: (title: String, message: String) {
        switch self {
        case .accountLocked:
            return ("Tafel in gebruik", "De tafel is momenteel in gebruik. Probeer later opnieuw.")
        case .tableEmpty:
            return ("Tafel leeg", "Er is geen bestelling in de tafel")
        case .tableContainsItems:
            return ("Fout", "De tafel bevat nog items.")
        }
    }
}

*/
