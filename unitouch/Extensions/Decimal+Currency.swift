//
//  Decimal+Currency.swift
//  unitouch
//
//  Created by Tijn Giesberts on 11/03/2026.
//

import Foundation

extension Decimal {
    public var toCurrency: String {
        return String(format: "%.2f", NSDecimalNumber(decimal:self).doubleValue )
    }
}
