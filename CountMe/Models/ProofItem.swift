//
//  ProofItem.swift
//  CountMe
//
//  Created by Adrian on 26/03/25.
//

import SwiftUI
import SwiftData

@Model
final class ProofItem {
    var dateTime2: Date
    var price2: Double
    var bankname: String
    
    init(dateTime: Date, proofImage: Image, price: Double, bankname: String) {
        self.dateTime2 = dateTime
        self.price2 = price
        self.bankname = bankname
    }
}
