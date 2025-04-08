import SwiftData
import SwiftUI
import PhotosUI

struct OrderListItem: View {
    let order: OrderItem
    @State private var showEditView = false
    @State private var showDeleteConfirmation = false
    @State private var showAddProofOptions = false
    @State private var showDocumentScanner = false
    @State private var showPhotoLibrary = false
    @State private var viewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext  // Inject SwiftData context
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()
    
    init(order: OrderItem) {
        self.order = order
        self._viewModel = State(initialValue: HomeViewModel(modelContext: ModelContext(AppSchema.container)))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(order.orderNumberTail)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                StatusBadge(status: order.verificationStatus)
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Text(order.dateTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer().frame(width: 16)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Text(order.dateTime, style: .time)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                Text(currencyFormatter.string(from: NSNumber(value: order.price)) ?? "Rp0")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(order.dishes, id: \.self) { dish in
                        Text(dish)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.systemGray5))
                            .foregroundStyle(Color.secondary)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .swipeActions(edge: .leading) {
            if order.verificationStatus == .pending {
                Button {
                    viewModel.orderBeingEdited = order
                    showAddProofOptions = true
                } label: {
                    Label("Scan Proof", systemImage: "doc.text.viewfinder")
                }
                .tint(.orange)
            }
            Button {
                showEditView = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            // When using swipeActions, use a simple action that sets the state
            Button(role: .destructive) {
                // The dialog will be shown via .confirmationDialog modifier
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        // This confirmation dialog is tied to the whole cell
        .confirmationDialog(
            "Delete Order",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteOrder()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this order?")
        }
        .confirmationDialog(
            "Proof input method",
            isPresented: $showAddProofOptions,
            actions: { confirmationDialogButtons },
            message: { Text("Select proof method") }
        )
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
            processSelectedPhotos(newItems)
        }
        // Document scanner
        .fullScreenCover(isPresented: $showDocumentScanner) {
            documentScannerView
        }
        // OCR results sheet
        .sheet(isPresented: $viewModel.showingOCRResults, onDismiss: {
            viewModel.resetImageSelection()
        }) {
            ocrResultsView
        }
        // Reset photo selection
        .onChange(of: showPhotoLibrary) { _, newValue in
            if newValue == true {
                viewModel.selectedPhotoItems = []
            }
        }
        // Processing overlay
        .overlay {
            processingOverlay
        }
        // Add sheet for EditVerifiedView
        .sheet(isPresented: $showEditView) {
            // On dismiss callback if needed
        } content: {
            // Get images from order data if available
            let receiptUIImage = order.receiptImage != nil ?
            UIImage(data: order.receiptImage!) ?? UIImage(systemName: "doc.text")! :
            UIImage(systemName: "doc.text")!
            
            let proofUIImage = order.proofImage != nil ?
            UIImage(data: order.proofImage!) ?? UIImage(systemName: "photo")! :
            UIImage(systemName: "photo")!
            
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
    }
    
    private func deleteOrder() {
        withAnimation {
            modelContext.delete(order)
            do {
                try modelContext.save()
                print("Order deleted successfully")
            } catch {
                print("Failed to delete order: \(error)")
            }
        }
    }
    
    private var confirmationDialogButtons: some View {
        Group {
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
        }
    }
    
    private var documentScannerView: some View {
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
    
    private var ocrResultsView: some View {
        SegmentedResultView(
            images: !viewModel.scannedImages.isEmpty ? viewModel.scannedImages : viewModel.selectedImages,
            recognizedTexts: viewModel.recognizedTexts,
            viewModel: viewModel
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var processingOverlay: some View {
        ProcessingOverlay(
            isVisible: viewModel.isProcessing,
            currentIndex: viewModel.processingIndex,
            totalCount: !viewModel.scannedImages.isEmpty
            ? viewModel.scannedImages.count
            : viewModel.selectedPhotoItems.count
        )
    }
    
    // Extract functions to simplify the body
    private func processSelectedPhotos(_ newItems: [PhotosPickerItem]) {
        guard !newItems.isEmpty else { return }
        Task {
            await viewModel.processSelectedPhotos()
        }
    }
    
    
}

//#Preview {
//    let container = AppSchema.previewContainer
//    let order = OrderItem.sampleOrders[0]
//    
//    return List {
//        OrderListItem(order: order)
//    }
//    .modelContainer(container)
//}
