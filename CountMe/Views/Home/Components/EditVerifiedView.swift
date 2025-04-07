import SwiftUI
import SwiftData

struct EditVerifiedView: View {
    @Bindable var order: OrderItem
    var receiptImage: UIImage?
    var paymentProofImage: UIImage?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var orderDateTime: Date
    @State private var price: Double
    @State private var sideDishes: String
    @State private var bankName: String = ""
    
    init(
        order: OrderItem,
        receiptImage: UIImage,
        onSave: @escaping (OrderItem) -> Void,
        paymentProofImage: UIImage
    ) {
        self.order = order
        self.receiptImage = receiptImage
        self.paymentProofImage = paymentProofImage
        
        // Initialize state variables with order properties
        self._title = State(initialValue: order.title)
        self._orderDateTime = State(initialValue: order.dateTime)
        self._price = State(initialValue: order.price)
        
        // Convert array of side dishes to comma-separated string
        let sideDishesString = order.sideDishes.joined(separator: ", ")
        self._sideDishes = State(initialValue: sideDishesString)
        
        // This could be extracted from proof image metadata in a real app
        self._bankName = State(initialValue: "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Receipt section
                    VStack(alignment: .leading) {
                        Text("Receipt")
                            .font(.headline)
                            .padding(.vertical, 5)
                        
                        if let receiptImage = receiptImage {
                            Image(uiImage: receiptImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                        } else if let receiptImageData = order.receiptImage,
                                  let uiImage = UIImage(data: receiptImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                        }
                        
                        GroupBox("Receipt Details") {
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Order Title")
                                    Spacer()
                                    TextField("Order Title", text: $title)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 200)
                                }
                                
                                DatePicker(
                                    "Date & Time",
                                    selection: $orderDateTime
                                )
                                
                                HStack {
                                    Text("Total Amount")
                                    Spacer()
                                    TextField("Total Amount", value: $price, format: .currency(code: "IDR"))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 150)
                                }
                                
                                HStack(alignment: .top) {
                                    Text("Side Dishes")
                                    Spacer()
                                    TextField("Side Dishes (comma separated)", text: $sideDishes, axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(3)
                                        .frame(width: 200)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    // Payment Proof section
                    VStack(alignment: .leading) {
                        Text("Proof of Purchase")
                            .font(.headline)
                            .padding(.vertical, 5)
                        
                        if let paymentProofImage = paymentProofImage {
                            Image(uiImage: paymentProofImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                        } else if let proofImageData = order.proofImage,
                                  let uiImage = UIImage(data: proofImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                        }
                        
                        GroupBox("Payment Details") {
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Bank Name")
                                    Spacer()
                                    TextField("Bank Name", text: $bankName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.organizationName)
                                        .frame(width: 150)
                                }
                                
                                HStack {
                                    Text("Payment Amount")
                                    Spacer()
                                    TextField("Payment Amount", value: $price, format: .currency(code: "IDR"))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 150)
                                }
                                
                                DatePicker(
                                    "Payment Date & Time",
                                    selection: $orderDateTime
                                )
                                
                                HStack {
                                    Text("Status")
                                    Spacer()
                                    Text(order.verificationStatus.rawValue)
                                        .foregroundColor(order.verificationStatus.color)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        Text("Save")
                            .font(.headline)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        // Update order properties with edited values
        order.title = title
        order.dateTime = orderDateTime
        order.price = price
        
        // Convert comma-separated string to array of side dishes
        order.sideDishes = sideDishes
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // If we had new images, we would convert and save them here
        // order.receiptImage = receiptImageData
        // order.proofImage = proofImageData
        
        // SwiftData automatically tracks these changes
        
        // Dismiss the view
        dismiss()
    }
}
