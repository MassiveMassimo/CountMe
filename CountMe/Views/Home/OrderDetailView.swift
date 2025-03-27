import SwiftUI
import SwiftData

struct OrderDetailView: View {
    @Bindable var order: OrderItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showAddProofOptions = false
    @State private var showDocumentScanner = false
    @State private var showPhotoLibrary = false
    @State private var viewModel = HomeViewModel(modelContext: ModelContext(AppSchema.container))
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()
    
    var body: some View {
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
                
                // Receipt Image
                if let receiptImageData = order.receiptImage,
                   let uiImage = UIImage(data: receiptImageData) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Receipt Image")
                            .font(.headline)
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                    }
                    .padding(.top, 10)
                }
                
                // Proof Image
                if let proofImageData = order.proofImage,
                   let uiImage = UIImage(data: proofImageData) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Proof")
                            .font(.headline)
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                    }
                    .padding(.top, 10)
                }
                
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
                        
                        if order.verificationStatus == .pending {
                            Button {
                                showAddProofOptions = true
//                                dismiss()
                            } label: {
                                Label("Scan Proof", systemImage: "doc.text.viewfinder")
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                        }
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Edit order functionality
                    
                } label: {
                    Text("Edit")
                }
            }
        }
        .confirmationDialog(
            "Proof input method",
            isPresented: $showAddProofOptions
        ) {
            Button("Take a photo") {
                showAddProofOptions = false
                showDocumentScanner = true
                
            }
            Button("Choose from gallery") {
                showAddProofOptions = false
                showPhotoLibrary = true
            }
            Button("Cancel", role: .cancel) {
                // Reset orderBeingEdited if user cancels
                viewModel.orderBeingEdited = nil
            }
        } message: {
            Text("Select proof method")
        }
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $viewModel.selectedPhotoItems,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: viewModel.selectedPhotoItems) { oldItems, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await viewModel.processSelectedPhotos()
            }
        }
        .fullScreenCover(isPresented: $showDocumentScanner) {
            DocumentScannerView(
                scannedImages: $viewModel.scannedImages,
                ocrService: viewModel.ocrService
            )
            .ignoresSafeArea()
            .onDisappear {
                if !viewModel.scannedImages.isEmpty {
                    Task {
                        await viewModel.processScannedDocuments()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingOCRResults, onDismiss: {
            viewModel.resetImageSelection()
        }) {
            MultiOCRResultView(
                images: !viewModel.scannedImages.isEmpty ? viewModel.scannedImages : viewModel.selectedImages,
                recognizedTexts: viewModel.recognizedTexts,
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showPhotoLibrary) { oldValue, newValue in
            if newValue == true {
                viewModel.selectedPhotoItems = []
            }
        }
        .overlay {
            ProcessingOverlay(
                isVisible: viewModel.isProcessing,
                currentIndex: viewModel.processingIndex,
                totalCount: !viewModel.scannedImages.isEmpty
                ? viewModel.scannedImages.count
                : viewModel.selectedPhotoItems.count
            )
        }
    }
}

// Preview for SwiftData
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: OrderItem.self, configurations: config)
        
        // Create a sample OrderItem
        let order = OrderItem(
            title: "Daging Lada Hitam",
            dateTime: Date(),
            price: 45000,
            sideDishes: ["Nasi Putih 1 Porsi", "Es Teh Manis"],
            verificationStatus: .verified
        )
        
        return NavigationStack {
            OrderDetailView(order: order)
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
