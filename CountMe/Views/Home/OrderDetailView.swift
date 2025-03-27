//import SwiftUI
//import SwiftData
//
//struct OrderDetailView: View {
//    @Bindable var order: OrderItem
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.modelContext) private var modelContext
//    
//    let currencyFormatter: NumberFormatter = {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.locale = Locale(identifier: "id_ID")
//        return formatter
//    }()
//    
//    var body: some View {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Order title and status
//                    HStack {
//                        Text(order.title)
//                            .font(.title2)
//                            .fontWeight(.bold)
//                        
//                        Spacer()
//                        
//                        StatusBadge(status: order.verificationStatus)
//                    }
//                    .padding(.bottom, 5)
//                    
//                    // Date and price information
//                    VStack(alignment: .leading, spacing: 8) {
//                        HStack {
//                            Label {
//                                Text(order.dateTime, style: .date)
//                            } icon: {
//                                Image(systemName: "calendar")
//                            }
//                            .foregroundStyle(.secondary)
//                            
//                            Spacer()
//                            
//                            Label {
//                                Text(order.dateTime, style: .time)
//                            } icon: {
//                                Image(systemName: "clock")
//                            }
//                            .foregroundStyle(.secondary)
//                        }
//                        
//                        // Price
//                        HStack {
//                            Text("Total Amount")
//                                .fontWeight(.medium)
//                            
//                            Spacer()
//                            
//                            Text(currencyFormatter.string(from: NSNumber(value: order.price)) ?? "Rp0")
//                                .font(.headline)
//                        }
//                        .padding(.top, 5)
//                    }
//                    .padding(.vertical, 10)
//                    .padding(.horizontal, 15)
//                    .background(Color(UIColor.systemGray6))
//                    .cornerRadius(12)
//                    
//                    // Side dishes
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Side Dishes")
//                            .font(.headline)
//                            .padding(.bottom, 2)
//                        
//                        if order.sideDishes.isEmpty {
//                            Text("No side dishes")
//                                .foregroundStyle(.secondary)
//                                .italic()
//                        } else {
//                            ForEach(order.sideDishes, id: \.self) { dish in
//                                HStack {
//                                    Image(systemName: "circle.fill")
//                                        .font(.system(size: 6))
//                                        .foregroundStyle(.secondary)
//                                    
//                                    Text(dish)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.top, 5)
//                    
//                    // Receipt Image
//                    if let receiptImageData = order.receiptImage,
//                       let uiImage = UIImage(data: receiptImageData) {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Receipt Image")
//                                .font(.headline)
//                            
//                            Image(uiImage: uiImage)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(maxWidth: .infinity)
//                                .cornerRadius(12)
//                        }
//                        .padding(.top, 10)
//                    }
//                    
//                    // Proof Image
//                    if let proofImageData = order.proofImage,
//                       let uiImage = UIImage(data: proofImageData) {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Verification Proof")
//                                .font(.headline)
//                            
//                            Image(uiImage: uiImage)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(maxWidth: .infinity)
//                                .cornerRadius(12)
//                        }
//                        .padding(.top, 10)
//                    }
//                    
//                    // Verification Info
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Verification Status")
//                            .font(.headline)
//                        
//                        HStack {
//                            Image(systemName: order.verificationStatus.iconName)
//                                .foregroundStyle(order.verificationStatus.color)
//                            
//                            Text(order.verificationStatus.rawValue)
//                                .foregroundStyle(order.verificationStatus.color)
//                            
//                            Spacer()
//                            
//                            if order.verificationStatus == .pending {
//                                Button {
//                                    // Scan verification proof
//                                    dismiss()
//                                } label: {
//                                    Label("Scan Proof", systemImage: "doc.text.viewfinder")
//                                }
//                                .buttonStyle(.bordered)
//                                .tint(.orange)
//                            }
//                        }
//                        .padding(10)
//                        .background(Color(UIColor.systemGray6))
//                        .cornerRadius(8)
//                    }
//                    .padding(.top, 10)
//                }
//                .padding()
//            }
//            .navigationTitle("Order Details")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        // Edit order functionality
//                    } label: {
//                        Text("Edit")
//                    }
//                }
//            }
//    }
//}
//
//// Preview for SwiftData
//#Preview {
//    do {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let container = try ModelContainer(for: OrderItem.self, configurations: config)
//        
//        // Create a sample OrderItem
//        let order = OrderItem(
//            title: "Daging Lada Hitam",
//            dateTime: Date(),
//            price: 45000,
//            sideDishes: ["Nasi Putih 1 Porsi", "Es Teh Manis"],
//            verificationStatus: .verified
//        )
//        
//        return NavigationStack {
//            OrderDetailView(order: order)
//        }
//        .modelContainer(container)
//    } catch {
//        return Text("Failed to create preview: \(error.localizedDescription)")
//    }
//}


import SwiftUI

struct OrderDetailView: View {
    @Bindable var order: OrderItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Order title and status
                    HStack {
                        Text(order.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        StatusBadge(status: order.verificationStatus)
                    }
                    .padding(.bottom, 5)
                    
                    // Date and price information
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label {
                                Text(order.dateTime, style: .date)
                            } icon: {
                                Image(systemName: "calendar")
                            }
                            .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Label {
                                Text(order.dateTime, style: .time)
                            } icon: {
                                Image(systemName: "clock")
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        // Price
                        HStack {
                            Text("Total Amount")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(currencyFormatter.string(from: NSNumber(value: order.price)) ?? "Rp0")
                                .font(.headline)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    
                    // Side dishes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Side Dishes")
                            .font(.headline)
                            .padding(.bottom, 2)
                        
                        if order.sideDishes.isEmpty {
                            Text("No side dishes")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(order.sideDishes, id: \.self) { dish in
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundStyle(.secondary)
                                    
                                    Text(dish)
                                }
                            }
                        }
                    }
                    .padding(.top, 5)
                    
                    // Verification Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Status")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: order.verificationStatus.iconName)
                                .foregroundStyle(order.verificationStatus.color)
                            
                            Text(order.verificationStatus.rawValue)
                                .foregroundStyle(order.verificationStatus.color)
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Tombol Edit yang akan membuka halaman edit
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: editVerifiedView(
                        parsedReceipt: ParsedReceipt(
                            restaurantName: "Mama Djempol",
                            orderNumber: "POS-260325-20",
                            dateTime: Date(),
                            mainDish: "Sapi",
                            mainDishPrice: 100,
                            sideDishes: [],
                            totalPrice: 200),
                        receiptImage: UIImage(systemName: "doc.text")!,
                        onSave: { _ in
                            print("Saved data")
                        },
                        parsedPaymentProof: ParsedPaymentProof(
                            dateTime2: Date(),
                            price2: 47000,
                            bankName: "BCA"
                        ),
                        paymentProofImage: UIImage(systemName: "photo")!
                    )) {
                        Text("Edit")
                            .font(.headline)
                    }
                }
            }
        }
    }
}

#Preview {
    let order = OrderItem(
        title: "Daging Lada Hitam",
        dateTime: Date(),
        price: 45000,
        sideDishes: ["Nasi Putih 1 Porsi", "Es Teh Manis"],
        verificationStatus: .verified
    )
    
    return OrderDetailView(order: order)
}
