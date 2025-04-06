import SwiftUI
import SwiftData

struct SegmentedResultView: View {
    let images: [UIImage]
    let recognizedTexts: [String]
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    @State private var showSaveConfirmation = false
    @State private var retakePhotoIndex: Int? = nil
    @State private var showRetakeOptions = false
    
    var body: some View {
        
        NavigationStack {
            VStack {
                if images.isEmpty {
                    ContentUnavailableView(
                        label: { Label("No Images", systemImage: "photo") },
                        description: { Text("No images were selected or processed") }
                    )
                } else {
                    // Tab selector for multiple images
                    if images.count > 1 {
                        Picker("Select Receipt", selection: $selectedTab) {
                            ForEach(0..<images.count, id: \.self) { index in
                                Text("\(index + 1)").tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }
                    
                    // Main content
                    if !viewModel.parsedReceipts.isEmpty && selectedTab < viewModel.parsedReceipts.count {
                        ReceiptDetailView(
                            parsedReceipt: viewModel.parsedReceipts[selectedTab],
                            receiptImage: images[selectedTab],
                            onSave: { updatedReceipt in
                                // Update the parsed receipt in the view model
                                viewModel.parsedReceipts[selectedTab] = updatedReceipt
                                
                                // Get the current image to save with the receipt
                                let imageToSave = images[selectedTab]
                                
                                // Create a new order from this receipt
                                viewModel.saveReceipt(at: selectedTab)
                                
                                // Show confirmation and dismiss after delay
                                showSaveConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    dismiss()
                                }
                            },
                            onRetake: {
                                retakePhotoIndex = selectedTab
                                showRetakeOptions = true
                            }
                        )
                    } else {
                        // Show loading or image with raw text
                        ScrollView {
                            VStack(alignment: .center, spacing: 20) {
                                if selectedTab < images.count {
                                    ZStack(alignment: .bottomTrailing) {
                                        Image(uiImage: images[selectedTab])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                            
                                        // Retake button
                                        Button(action: {
                                            retakePhotoIndex = selectedTab
                                            showRetakeOptions = true
                                        }) {
                                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(Circle().fill(Color.accentColor))
                                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                                        }
                                        .padding([.bottom, .trailing], 24)
                                    }
                                }
                                
                                if viewModel.isProcessing {
                                    ProgressView("Analyzing receipt...")
                                        .padding()
                                } else if selectedTab < recognizedTexts.count {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("Recognized Text:")
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            Button {
                                                UIPasteboard.general.string = recognizedTexts[selectedTab]
                                            } label: {
                                                Label("Copy", systemImage: "doc.on.doc")
                                            }
                                        }
                                        
                                        Text(recognizedTexts[selectedTab].isEmpty ? "No text recognized" : recognizedTexts[selectedTab])
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                    .padding(.horizontal)
                                    
                                    Button("Parse Receipt Manually") {
                                        // Parse the current receipt text
                                        let parser = ReceiptParserService()
                                        let parsedReceipt = parser.parseReceipt(from: recognizedTexts[selectedTab])
                                        
                                        // Update or add to viewModel's parsedReceipts
                                        if selectedTab < viewModel.parsedReceipts.count {
                                            viewModel.parsedReceipts[selectedTab] = parsedReceipt
                                        } else {
                                            viewModel.parsedReceipts.append(parsedReceipt)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Receipt Details")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .primaryAction) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
            .overlay {
                if showSaveConfirmation {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Order Added!")
                                .font(.headline)
                                .padding(.top)
                        }
                        .padding(30)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                        .shadow(radius: 10)
                    }
                }
            }
            .confirmationDialog(
                "Retake Receipt",
                isPresented: $showRetakeOptions
            ) {
                Button("Take a photo") {
                    guard let index = retakePhotoIndex else { return }
                    // Logic to retake photo would go here
                    // For now, just dismiss and let the main view handle it
                    dismiss()
                }
                Button("Choose from gallery") {
                    guard let index = retakePhotoIndex else { return }
                    // Logic to select from gallery would go here
                    // For now, just dismiss and let the main view handle it
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    retakePhotoIndex = nil
                }
            } message: {
                Text("Select input method")
            }
        }
    }
}

#Preview("Single Image") {
    // Create a model container
    let container = try! ModelContainer(for: OrderItem.self)
    let context = container.mainContext
    
    // Initialize ViewModel with the context
    let viewModel = HomeViewModel(modelContext: context)
    
    let sampleImage = UIImage(systemName: "doc.text")!
    
    let sampleText = """
    RECEIPT
    Daging Lada Hitam    $45
    Nasi Putih 1 Porsi   $5
    Es Teh Manis         $3
    Total:               $53
    Date: 2024-03-26
    """
    
    let sampleParsedReceipt = ParsedReceipt(
        dateTime: Date(),
        mainDish: "Daging Lada Hitam",
        sideDishes: [(name: "Nasi Putih 1 Porsi",price: 15.5),
                     (name: "sate",price: 17)
                    ],
        totalPrice: 53.0
        )
    
    viewModel.parsedReceipts = [sampleParsedReceipt]
    viewModel.selectedImages = [sampleImage]
    viewModel.recognizedTexts = [sampleText]
    
    return AnyView(
            MultiOCRResultView(
                images: [sampleImage],
                recognizedTexts: [sampleText],
                viewModel: viewModel
            )
        )
}

#Preview("Multiple Images") {
    // Create a model container
    let container = try! ModelContainer(for: OrderItem.self)
    let context = container.mainContext
    
    // Initialize ViewModel with the context
    let viewModel = HomeViewModel(modelContext: context)
    
    let sampleImages = [
        UIImage(systemName: "doc.text")!,
        UIImage(systemName: "doc.text.fill")!
    ]
    
    let sampleTexts = [
        """
        RECEIPT 1
        Daging Lada Hitam    $45
        Nasi Putih 1 Porsi   $5
        Es Teh Manis         $3
        Total:               $53
        Date: 2024-03-26
        """,
        """
        RECEIPT 2
        Ayam Bakar Madu      $38
        Nasi Putih 1 Porsi   $5
        Sayur Asem           $4
        Es Jeruk             $3
        Total:               $50
        Date: 2024-03-27
        """
    ]
    
    let sampleParsedReceipts = [
        ParsedReceipt(
            dateTime: Date(),
            mainDish: "Daging Lada Hitam",
            sideDishes: [(name: "Nasi Putih 1 Porsi",price: 15.5),
                         (name: "sate",price: 17)
                        ],
            totalPrice: 32.5
        ),
        ParsedReceipt(
            dateTime: Date(),
            mainDish: "Ayam Bakar",
            sideDishes: [(name: "Nasi Putih 2 Porsi",price: 18.5),
                         (name: "sate",price: 20)
                        ],
            totalPrice: 38.5
        )
    ]
    
    viewModel.parsedReceipts = sampleParsedReceipts
    viewModel.selectedImages = sampleImages
    viewModel.recognizedTexts = sampleTexts
    
    return AnyView(
            MultiOCRResultView(
                images: sampleImages,
                recognizedTexts: sampleTexts,
                viewModel: viewModel
            )
        )
}
