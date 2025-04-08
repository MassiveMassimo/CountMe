import SwiftUI
import SwiftData

@Model
final class OrderItem {
    var orderNumber: String
    var orderNumberTail: String
    var dateTime: Date
    var price: Double
    @Attribute(.externalStorage) var receiptImage: Data?
    @Attribute(.externalStorage) var proofImage: Data?
    var dishes: [String]
    var verificationStatus: VerificationStatus
    var createdAt: Date
    var restaurantName: String
    var paymentMethod: String
    
    init(
        orderNumber: String,
        dateTime: Date,
        price: Double,
        receiptImage: Data? = nil,
        proofImage: Data? = nil,
        dishes: [String],
        verificationStatus: VerificationStatus,
        restaurantName: String = "",
        paymentMethod: String = ""
    ) {
        self.orderNumber = orderNumber
        let components = orderNumber.split(separator: "-")
        self.orderNumberTail = components.last.map(String.init) ?? orderNumber
        self.dateTime = dateTime
        self.price = price
        self.receiptImage = receiptImage
        self.proofImage = proofImage
        self.dishes = dishes
        self.verificationStatus = verificationStatus
        self.createdAt = Date()
        self.restaurantName = restaurantName
        self.paymentMethod = paymentMethod
    }
    
    enum VerificationStatus: String, Codable {
        case verified = "Verified"
        case pending = "Pending"
        case mismatch = "Mismatch"
        
        var color: Color {
            switch self {
            case .verified:
                return .green
            case .pending:
                return .orange
            case .mismatch:
                return .red
            }
        }
        
        var iconName: String {
            switch self {
            case .verified:
                return "checkmark.circle.fill"
            case .pending:
                return "clock.fill"
            case .mismatch:
                return "xmark.circle.fill"
            }
        }
    }
}

// Sample data for previews
extension OrderItem {
    static var sampleOrders: [OrderItem] {
        [
            OrderItem(
                orderNumber: "ORD-12345",
                dateTime: Date().addingTimeInterval(-3600),
                price: 45000,
                dishes: ["Daging Lada Hitam", "Nasi Putih 1 Porsi", "Es Teh Manis"],
                verificationStatus: .verified,
                restaurantName: "Warung Nusantara"
            ),
            OrderItem(
                orderNumber: "ORD-67890",
                dateTime: Date().addingTimeInterval(-7200),
                price: 38000,
                dishes: ["Ayam Bakar Madu", "Nasi Putih 1 Porsi", "Sayur Asem", "Es Jeruk"],
                verificationStatus: .pending,
                restaurantName: "Rumah Makan Sederhana"
            ),
            OrderItem(
                orderNumber: "ORD-54321",
                dateTime: Date().addingTimeInterval(-10800),
                price: 65000,
                dishes: ["Ikan Gurame Asam Manis", "Nasi Putih 2 Porsi", "Capcay Goreng"],
                verificationStatus: .pending,
                restaurantName: "Seafood Bahari"
            )
        ]
    }
}
