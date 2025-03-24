import SwiftUI

struct OrderItem: Identifiable {
    let id = UUID()
    let title: String
    let dateTime: Date
    let price: Double
    let sideDishes: [String]
    var verificationStatus: VerificationStatus
    
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
        ),
        OrderItem(
            title: "Tongseng Kambing",
            dateTime: Date().addingTimeInterval(-5400),
            price: 50000,
            sideDishes: ["Nasi Putih 1 Porsi", "Kerupuk Udang"],
            verificationStatus: .verified
        ),
        OrderItem(
            title: "Nasi Goreng Spesial",
            dateTime: Date().addingTimeInterval(-36000),
            price: 30000,
            sideDishes: ["Telur Ceplok", "Acar Timun", "Krupuk"],
            verificationStatus: .pending
        ),
        OrderItem(
            title: "Bakso Malang",
            dateTime: Date().addingTimeInterval(-18000),
            price: 25000,
            sideDishes: ["Tahu Isi", "Kerupuk Pangsit"],
            verificationStatus: .verified
        ),
        OrderItem(
            title: "Mie Ayam Jamur",
            dateTime: Date().addingTimeInterval(-27000),
            price: 20000,
            sideDishes: ["Bakso Kecil 2 Butir", "Kerupuk"],
            verificationStatus: .pending
        ),
        OrderItem(
            title: "Rendang Sapi",
            dateTime: Date().addingTimeInterval(-144000),
            price: 55000,
            sideDishes: ["Nasi Putih 1 Porsi", "Sambal Hijau", "Kerupuk"],
            verificationStatus: .verified
        )
    ]
}
