

import Foundation

struct ParsedPaymentProof {
    var dateTime2: Date?
    var price2: Double = 0.0
    var bankName: String?
}


let samplePayment1 = ParsedPaymentProof(
    dateTime2: Date(),  // Berikan nilai untuk dateTime2
    price2: 47000,      // Berikan nilai untuk price2
    bankName: "BCA"     // Berikan nilai untuk bankName
)
