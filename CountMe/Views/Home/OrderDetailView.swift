import SwiftUI
import SwiftData

// MARK: - Helper Components
struct OrderHeaderView: View {
    let order: OrderItem
    
    var body: some View {
        HStack {
            Text(order.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            StatusBadge(status: order.verificationStatus)
        }
        .padding(.bottom, 5)
    }
}

struct OrderDatePriceView: View {
    let order: OrderItem
    let currencyFormatter: NumberFormatter
    
    var body: some View {
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
    }
}

struct SideDishesView: View {
    let sideDishes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Side Dishes")
                .font(.headline)
                .padding(.bottom, 2)
            
            if sideDishes.isEmpty {
                Text("No side dishes")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(sideDishes, id: \.self) { dish in
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
    }
}

struct ImageDisplayView: View {
    let title: String
    let imageData: Data?
    
    var body: some View {
        if let imageData = imageData,
           let uiImage = UIImage(data: imageData) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        } else {
            EmptyView()
        }
    }
}

struct VerificationStatusView: View {
    let status: OrderItem.VerificationStatus
    let showAddProof: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verification Status")
                .font(.headline)
            
            HStack {
                Image(systemName: status.iconName)
                    .foregroundStyle(status.color)
                
                Text(status.rawValue)
                    .foregroundStyle(status.color)
                
                Spacer()
                
                if status == .pending {
                    Button {
                        showAddProof()
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
}

// MARK: - Main View
struct OrderDetailView: View {
    @Bindable var order: OrderItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // State variables
    @State private var showAddProofOptions = false
    @State private var showDocumentScanner = false
    @State private var showPhotoLibrary = false
    @State private var viewModel: HomeViewModel
    @State private var showEditView = false
    
    // Formatters
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()
    
    // Initialize with a new ModelContext to avoid compiler issues
    init(order: OrderItem) {
        self.order = order
        self._viewModel = State(initialValue: HomeViewModel(modelContext: ModelContext(AppSchema.container)))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Extract components to reduce complexity
                OrderHeaderView(order: order)
                OrderDatePriceView(order: order, currencyFormatter: currencyFormatter)
                SideDishesView(sideDishes: order.sideDishes)
                ImageDisplayView(title: "Receipt Image", imageData: order.receiptImage)
                ImageDisplayView(title: "Verification Proof", imageData: order.proofImage)
                
                VerificationStatusView(status: order.verificationStatus) {
                    showAddProofOptions = true
                }
            }
            .padding()
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditView = true
                } label: {
                    Text("Edit")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showEditView) {
            // When the sheet is dismissed, we could refresh data if needed
        } content: {
            // Get images from order data if available
            let receiptUIImage = order.receiptImage != nil ? UIImage(data: order.receiptImage!) ?? UIImage(systemName: "doc.text")! : UIImage(systemName: "doc.text")!
            let proofUIImage = order.proofImage != nil ? UIImage(data: order.proofImage!) ?? UIImage(systemName: "photo")! : UIImage(systemName: "photo")!
            
            EditVerifiedView(
                order: order,
                receiptImage: receiptUIImage,
                onSave: { updatedOrder in
                    // SwiftData will automatically track changes to the order
                    // Additional logic if needed after saving
                },
                paymentProofImage: proofUIImage
            )
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
                viewModel.orderBeingEdited = nil
            }
        } message: {
            Text("Select proof method")
        }
        // Apply modifiers to handle photo selection
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $viewModel.selectedPhotoItems,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        )
        // Process selected photos
        .onChange(of: viewModel.selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await viewModel.processSelectedPhotos()
            }
        }
        // Document scanner
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
        // OCR results sheet
        .sheet(isPresented: $viewModel.showingOCRResults, onDismiss: {
            viewModel.resetImageSelection()
        }) {
            SegmentedResultView(
                images: !viewModel.scannedImages.isEmpty ? viewModel.scannedImages : viewModel.selectedImages,
                recognizedTexts: viewModel.recognizedTexts,
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // Reset photo selection
        .onChange(of: showPhotoLibrary) { _, newValue in
            if newValue == true {
                viewModel.selectedPhotoItems = []
            }
        }
        // Processing overlay
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
