

import SwiftUI

//struct editVerifiedView: View {
//    
//    var parsedReceipt: ParsedReceipt
//    var receiptImage: UIImage
//    @State private var editedReceipt: ParsedReceipt
//    var onSave: (ParsedReceipt) -> Void
//    var bankname: String
//    var amountpayment: Double
//    
//    var parsedPaymentProof: ParsedPaymentProof
//    var paymentProofImage: UIImage
//    @State private var editedPaymentProof: ParsedPaymentProof
//    var price2: Double
//    
//    init(parsedReceipt: ParsedReceipt,
//         receiptImage: UIImage,
//         onSave: @escaping (ParsedReceipt) -> Void,
//         parsedPaymentProof: ParsedPaymentProof,
//         paymentProofImage: UIImage) {
//        self.parsedReceipt = parsedReceipt
//        self.receiptImage = receiptImage
//        self._editedReceipt = State(initialValue: parsedReceipt)  // Properti @State diinisialisasi
//        self.onSave = onSave
//        self.parsedPaymentProof = parsedPaymentProof  // Inisialisasi parsedPaymentProof
//        self.paymentProofImage = paymentProofImage  // Inisialisasi paymentProofImage
//        self._editedPaymentProof = State(initialValue: parsedPaymentProof) // <-- Inisialisasi @State untuk editedPaymentProof
//        self.bankname = ""
//        self.amountpayment = 0
//        self.price2 = 0.0
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack {
//                Text("Receipt")
//                    .font(.headline)
//                Image(uiImage: receiptImage)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxWidth: .infinity)
//                    .cornerRadius(12)
//                    .shadow(radius: 8)
//            }
//            
//            VStack {
//                GroupBox("Receipts") {
//                    VStack {
//                        HStack {
//                            Text("Restaurant Name")
//                            Spacer()
//                            TextField("Restaurant Name", text: $editedReceipt.restaurantName)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .textContentType(.organizationName)
//                                .frame(width: 200)
//                        }
//                        
//                        HStack {
//                            Text("Order Number")
//                            Spacer()
//                            TextField("Order Number", text: $editedReceipt.orderNumber)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .frame(width: 200)
//                        }
//                        
//                        HStack {
//                            Text("Total Amount")
//                            Spacer()
//                            TextField("Total Amount", value: $editedReceipt.totalPrice, format: .currency(code: "IDR"))
//                                .keyboardType(.decimalPad)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .frame(width: 150)
//                        }
//                        
//                        if let dateTime = editedReceipt.dateTime {
//                            DatePicker("Date & Time", selection: Binding(get: { dateTime },
//                                set: { editedReceipt.dateTime = $0 }))
//                                
//                        }
//                    }
//                }
//            }
//            Spacer()
//                .padding(.vertical, 24)
//            VStack {
//                Text("Proof of Purchase")
//                    .font(.headline)
//                Image(uiImage: receiptImage)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxWidth: .infinity)
//                    .cornerRadius(12)
//                    .shadow(radius: 8)
//            }
//            
//            VStack {
//                GroupBox("Proof of Purchase") {
//                    VStack {
//                        HStack {
//                            Text("Bank Name")
//                            Spacer()
//                            TextField("Bank Name", text: Binding(
//                                get: { editedPaymentProof.bankName ?? "" },
//                                set: { editedPaymentProof.bankName = $0 }
//                            ))
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .textContentType(.organizationName)
//                            .frame(width: 150)
//                        }
////                        HStack {
////                            Text("Order Number")
////                            Spacer()
////                            TextField("Order Number", text: $editedReceipt.orderNumber)
////                                .textFieldStyle(RoundedBorderTextFieldStyle())
////                                .frame(width: 200)
////                        }
//                        HStack {
//                            Text("Total Amount")
//                            Spacer()
//                            TextField("Total Amount", value: $editedReceipt.totalPrice, format: .currency(code: "IDR"))
//                                .keyboardType(.decimalPad)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .frame(width: 150)
//                        }
//                        
//                        if let dateTime = editedReceipt.dateTime {
//                            DatePicker("Date & Time", selection: Binding(get: { dateTime },
//                                set: { editedReceipt.dateTime = $0 }))
//                                
//                        }
//                    }
//                }
//            }
//            
//        }
//    }
//}

import SwiftUI

struct editVerifiedView: View {
    
    var parsedReceipt: ParsedReceipt
    var receiptImage: UIImage
    @State private var editedReceipt: ParsedReceipt
    var onSave: (ParsedReceipt) -> Void
    var bankname: String
    var amountpayment: Double
    
    var parsedPaymentProof: ParsedPaymentProof
    var paymentProofImage: UIImage
    @State private var editedPaymentProof: ParsedPaymentProof
    var price2: Double
    
    init(parsedReceipt: ParsedReceipt,
         receiptImage: UIImage,
         onSave: @escaping (ParsedReceipt) -> Void,
         parsedPaymentProof: ParsedPaymentProof,
         paymentProofImage: UIImage) {
        self.parsedReceipt = parsedReceipt
        self.receiptImage = receiptImage
        self._editedReceipt = State(initialValue: parsedReceipt)
        self.onSave = onSave
        self.parsedPaymentProof = parsedPaymentProof
        self.paymentProofImage = paymentProofImage
        self._editedPaymentProof = State(initialValue: parsedPaymentProof)
        self.bankname = ""
        self.amountpayment = 0
        self.price2 = 0.0
    }
    
    var body: some View {
        VStack {
            NavigationStack {
                ScrollView {
                    VStack {
                        Text("Receipt")
                            .font(.headline)
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    }
                    .navigationTitle("Edit Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                self.onSave(self.editedReceipt)
                            }) {
                                Text("Save")
                                    .font(.headline)
                            }
                        }
                        
                    }
                    VStack {
                        GroupBox("Receipts") {
                            VStack {
                                HStack {
                                    Text("Restaurant Name")
                                    Spacer()
                                    TextField("Restaurant Name", text: $editedReceipt.restaurantName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.organizationName)
                                        .frame(width: 200)
                                }
                                
                                HStack {
                                    Text("Order Number")
                                    Spacer()
                                    TextField("Order Number", text: $editedReceipt.orderNumber)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 200)
                                }
                                
                                HStack {
                                    Text("Total Amount")
                                    Spacer()
                                    TextField("Total Amount", value: $editedReceipt.totalPrice, format: .currency(code: "IDR"))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 150)
                                }
                                
                                if let dateTime = editedReceipt.dateTime {
                                    DatePicker("Date & Time", selection: Binding(get: { dateTime },
                                                                                 set: { editedReceipt.dateTime = $0 }))
                                }
                            }
                        }
                    }
                    
                    Spacer()
                        .padding(.vertical, 24)
                    
                    VStack {
                        Text("Proof of Purchase")
                            .font(.headline)
                        Image(uiImage: paymentProofImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    }
                    
                    VStack {
                        GroupBox("Proof of Purchase") {
                            VStack {
                                HStack {
                                    Text("Bank Name")
                                    Spacer()
                                    TextField("Bank Name", text: Binding(
                                        get: { editedPaymentProof.bankName ?? "" },
                                        set: { editedPaymentProof.bankName = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.organizationName)
                                    .frame(width: 150)
                                }
                                HStack {
                                    Text("Total Amount")
                                    Spacer()
                                    TextField("Total Amount", value: $editedReceipt.totalPrice, format: .currency(code: "IDR"))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 150)
                                }
                                
                                if let dateTime = editedReceipt.dateTime {
                                    DatePicker("Date & Time", selection: Binding(get: { dateTime },
                                                                                 set: { editedReceipt.dateTime = $0 }))
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
}


let sampleReceipt = ParsedReceipt(
    restaurantName: "Mama Djempol GOP",
    orderNumber: "POS-260325-20",
    dateTime: Date(),
    mainDish: "Sapi Putih",
    mainDishPrice: 30000,
    sideDishes: [("Kol", 2000), ("Nasi Merah", 15000)],
    totalPrice: 47000
   )
let samplePayment = ParsedPaymentProof(
    dateTime2: Date(),
    price2: 47000,
    bankName: "BCA"
)

#Preview {
    editVerifiedView(
        parsedReceipt: sampleReceipt,
        receiptImage: UIImage(systemName: "doc.text")!,
        onSave: { _ in },
        parsedPaymentProof: samplePayment,   // <-- Pastikan parameter ini terisi
        paymentProofImage: UIImage(systemName: "doc.text")!  // <-- Pastikan parameter ini terisi
    )
}

