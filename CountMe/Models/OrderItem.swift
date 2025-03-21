import SwiftUI

struct OrderItem: Identifiable {
    let id = UUID()
    let title: String
    let dateTime: Date
    let price: Double
    let sideDishes: [String]
    let verificationStatus: VerificationStatus
    
    enum VerificationStatus: String {
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

// Sample data for previews
extension OrderItem {
    static var sampleOrders: [OrderItem] = [
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
        ),
        OrderItem(
            title: "Cumi Goreng Tepung",
            dateTime: Date().addingTimeInterval(-86400),
            price: 42000,
            sideDishes: ["Nasi Putih 1 Porsi", "Es Kelapa Muda"],
            verificationStatus: .verified
        ),
        OrderItem(
            title: "Sate Ayam",
            dateTime: Date().addingTimeInterval(-86400 * 2),
            price: 35000,
            sideDishes: ["Nasi Putih 1 Porsi", "Lontong", "Teh Botol"],
            verificationStatus: .pending
        )
    ]
}
