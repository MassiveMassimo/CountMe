import SwiftUI
import SwiftData

@Model
final class OrderItem {
    var title: String
    var dateTime: Date
    var price: Double
    @Attribute(.externalStorage) var receiptImage: Data?
    @Attribute(.externalStorage) var proofImage: Data?
    var sideDishes: [String]
    var verificationStatus: VerificationStatus
    var createdAt: Date
    
    init(
        title: String,
        dateTime: Date,
        price: Double,
        receiptImage: Data? = nil,
        proofImage: Data? = nil,
        sideDishes: [String],
        verificationStatus: VerificationStatus
    ) {
        self.title = title
        self.dateTime = dateTime
        self.price = price
        self.receiptImage = receiptImage
        self.proofImage = proofImage
        self.sideDishes = sideDishes
        self.verificationStatus = verificationStatus
        self.createdAt = Date()
        
    }
    
    enum VerificationStatus: String, Codable {
        case verified = "Verified"
        case pending = "Pending"
        
        var color: Color {
            switch self {
            case .verified:
                return .green
            case .pending:
                return .orange
            }
        }
        
        var iconName: String {
            switch self {
            case .verified:
                return "checkmark.circle.fill"
            case .pending:
                return "clock.fill"
            }
        }
    }
}


final class PaymentDetail {
    var bank: String
    var paymentamount: Double
    
    init(
        bank: String,
        paymentamount: Double
    ) {
        self.bank = bank
        self.paymentamount = paymentamount
    }
    
}

// Sample data for previews
extension OrderItem {
    static var sampleOrders: [OrderItem] {
        [
            OrderItem(
                title: "Daging Lada Hitam",
                dateTime: Date().addingTimeInterval(-3600),
                price: 45000,
                sideDishes: ["Nasi Putih 1 Porsi", "Es Teh Manis"],
                verificationStatus: .verified
            ),
            OrderItem(
                title: "Ayam Bakar Madu",
                dateTime: Date().addingTimeInterval(-7200),
                price: 38000,
                sideDishes: ["Nasi Putih 1 Porsi", "Sayur Asem", "Es Jeruk"],
                verificationStatus: .pending
            ),
            OrderItem(
                title: "Ikan Gurame Asam Manis",
                dateTime: Date().addingTimeInterval(-10800),
                price: 65000,
                sideDishes: ["Nasi Putih 2 Porsi", "Capcay Goreng"],
                verificationStatus: .pending
            )
        ]
    }
}
