import SwiftData
import Foundation

func createHomePreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: OrderItem.self, configurations: config)
        let context = ModelContext(container)
        
        // Add sample orders
        for order in OrderItem.sampleOrders {
            context.insert(order)
        }
        
        let pastDate1 = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let pastDate2 = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        let pastDate3 = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        
        context.insert(OrderItem(title: "Udang Saus Tiram", dateTime: pastDate1, price: 55000, sideDishes: ["Nasi Putih 1 Porsi", "Tahu Telur", "Es Kelapa"], verificationStatus: .verified))
        context.insert(OrderItem(title: "Sate Ayam", dateTime: pastDate2, price: 35000, sideDishes: ["Lontong", "Sambal Kacang"], verificationStatus: .pending))
        context.insert(OrderItem(title: "Nasi Goreng Seafood", dateTime: pastDate3, price: 42000, sideDishes: ["Telur Dadar", "Kerupuk", "Es Teh"], verificationStatus: .verified))
        context.insert(OrderItem(title: "Mie Goreng Spesial", dateTime: Date().addingTimeInterval(-14400), price: 38500, sideDishes: ["Bakso 3 buah", "Pangsit Goreng"], verificationStatus: .pending))
        context.insert(OrderItem(title: "Soto Ayam", dateTime: Date().addingTimeInterval(-18000), price: 32000, sideDishes: ["Nasi Putih 1 Porsi", "Emping", "Es Jeruk"], verificationStatus: .pending))
        
        return container
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}
