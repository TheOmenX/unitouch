//
//  Decimal+Currency.swift
//  unitouch
//
//  Created by Tijn Giesberts on 11/03/2026.
//

import Foundation

extension Decimal {
    public var toCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "0.00"
    }
}
