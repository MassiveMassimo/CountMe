import SwiftUI

struct ProofDetailView: View {
    var parsedProof: ParsedProof
    var proofImage: UIImage
    @State private var editedProof: ParsedProof
    @State private var showRawData = false
    @State private var showRetakeOptions = false
    
    var onSave: (ParsedProof) -> Void
    var onRetake: () -> Void
    
    init(parsedProof: ParsedProof,
         proofImage: UIImage,
         onSave: @escaping (ParsedProof) -> Void,
         onRetake: @escaping () -> Void) {
        self.parsedProof = parsedProof
        self.proofImage = proofImage
        self._editedProof = State(initialValue: parsedProof)
        self.onSave = onSave
        self.onRetake = onRetake
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Receipt image preview with retake button
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: proofImage)
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
                    GroupBox("Payment Info") {
                        VStack(alignment: .leading, spacing: 12) {
                       
                            if let dateTime = editedProof.dateTime {
                                DatePicker("Date & Time", selection: Binding(
                                    get: { dateTime },
                                    set: { editedProof.dateTime = $0 }
                                ))
                            } else {
                                Text("Date not recognized")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Total Amount")
                                Spacer()
                                TextField("Total", value: $editedProof.totalPayment, format: .currency(code: "IDR"))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 150)
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
                        
                        Button("Save Payment") {
                            onSave(editedProof)
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
            RawOCRDataView(rawText: parsedProof.rawText)
        }
    }
}

#Preview {
    let sampleProof = ParsedProof(
        dateTime: Date(),
        totalPayment: 25000,
        rawText: "Sample OCR text"
    )
    
    NavigationStack {
        ProofDetailView(
            parsedProof: sampleProof,
            proofImage: UIImage(systemName: "doc.text")!,
            onSave: { _ in },
            onRetake: { }
        )
    }
}
