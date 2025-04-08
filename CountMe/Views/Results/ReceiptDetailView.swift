import SwiftUI

struct ReceiptDetailView: View {
    var parsedReceipt: ParsedReceipt
    var receiptImage: UIImage
    @State private var editedReceipt: ParsedReceipt
    @State private var showRawData = false
    @State private var showRetakeOptions = false
    var onSave: (ParsedReceipt) -> Void
    var onRetake: () -> Void
    
    init(parsedReceipt: ParsedReceipt,
         receiptImage: UIImage,
         onSave: @escaping (ParsedReceipt) -> Void,
         onRetake: @escaping () -> Void) {
        self.parsedReceipt = parsedReceipt
        self.receiptImage = receiptImage
        self._editedReceipt = State(initialValue: parsedReceipt)
        self.onSave = onSave
        self.onRetake = onRetake
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Receipt image preview with retake button
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: receiptImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    
                    // Retake button
                    Button(action: {
                        showRetakeOptions = true
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.accentColor))
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                    }
                    .padding([.bottom, .trailing], 16)
                }
                .padding(.horizontal)
                
                // Form fields for receipt data
                VStack(spacing: 16) {
                    GroupBox("Restaurant Info") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Restaurant Name", text: $editedReceipt.restaurantName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.organizationName)
                            
                            TextField("Order Number", text: $editedReceipt.orderNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if let dateTime = editedReceipt.dateTime {
                                DatePicker("Date & Time", selection: Binding(
                                    get: { dateTime },
                                    set: { editedReceipt.dateTime = $0 }
                                ))
                            } else {
                                Text("Date not recognized")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(0..<editedReceipt.dishes.count, id: \.self) { index in
                                VStack(spacing: 8) {
                                    TextField("Name", text: Binding(
                                        get: { editedReceipt.dishes[index].name },
                                        set: { editedReceipt.dishes[index].name = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    HStack {
                                        Text("Price")
                                        Spacer()
                                        TextField("Price", value: Binding(
                                            get: { editedReceipt.dishes[index].price },
                                            set: { editedReceipt.dishes[index].price = $0 }
                                        ), format: .currency(code: "IDR"))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 150)
                                    }
                                }
                                
                                if index < editedReceipt.dishes.count - 1 {
                                    Divider()
                                }
                            }
                            
                            Button {
                                withAnimation {
                                    editedReceipt.dishes.append((name: "", price: 0.0))
                                }
                            } label: {
                                Label("Add Dish", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    } label: {
                        HStack {
                            Text("Dishes")
                            Spacer()
                            Text("\(editedReceipt.dishes.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    GroupBox("Total") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Total Amount")
                                Spacer()
                                TextField("Total", value: $editedReceipt.totalPrice, format: .currency(code: "IDR"))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 150)
                            }
                            
                            if editedReceipt.totalPrice != editedReceipt.calculatedTotal {
                                HStack {
                                    Text("Calculated Total")
                                    Spacer()
                                    Text(editedReceipt.calculatedTotal, format: .currency(code: "IDR"))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    HStack {
                        Button("View Raw OCR Data") {
                            showRawData.toggle()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button("Save Order") {
                            onSave(editedReceipt)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .confirmationDialog(
            "Retake Receipt",
            isPresented: $showRetakeOptions
        ) {
            Button("Take a new photo") {
                onRetake()
            }
            Button("Choose from gallery") {
                onRetake()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select input method")
        }
        .sheet(isPresented: $showRawData) {
            RawOCRDataView(rawText: parsedReceipt.rawText)
        }
    }
}

//#Preview {
//    let sampleReceipt = ParsedReceipt(
//        restaurantName: "Mama Djempol Binong",
//        orderNumber: "POS-170325-99",
//        dateTime: Date(),
//        mainDish: "Daging Sapi lada Hitam",
//        mainDishPrice: 16000,
//        sideDishes: [
//            (name: "Kentang Mustopa", price: 5000),
//            (name: "Nasi Putih", price: 4000)
//        ],
//        totalPrice: 25000,
//        rawText: "Sample OCR text"
//    )
//    
//    return NavigationStack {
//        ReceiptDetailView(
//            parsedReceipt: sampleReceipt,
//            receiptImage: UIImage(systemName: "doc.text")!,
//            onSave: { _ in },
//            onRetake: { }
//        )
//    }
//}
