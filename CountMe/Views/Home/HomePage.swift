import SwiftUI
import PhotosUI
import VisionKit

struct HomePage: View {
    @StateObject private var viewModel = HomeViewModel()
    
    // Local UI state
    @State private var showDeleteConfirmation = false
    @State private var showAddReceiptOptions = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentScanner = false
    @State private var orderToDelete: OrderItem?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter header
                Picker("Filter", selection: $viewModel.currentFilter) {
                    ForEach(OrderFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.graySurface)
                
                // Order list
                OrderListView(
                    orders: viewModel.filteredOrders,
                    onDelete: { order in
                        orderToDelete = order
                        showDeleteConfirmation = true
                    },
                    onEdit: { order in
                        viewModel.editOrder(order)
                    }
                )
            }
            .navigationTitle("CountMe")
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if viewModel.filteredOrders.isEmpty {
                    EmptyStateView {
                        showAddReceiptOptions = true
                    }
                }
            }
            .confirmationDialog(
                "Delete Order",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let order = orderToDelete {
                        viewModel.deleteOrder(order)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this order?")
            }
            .overlay(alignment: .bottom) {
                Button("Add receipt", systemImage: "doc.text.viewfinder") {
                    showAddReceiptOptions = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .cornerRadius(16)
                .padding(.horizontal)
                .confirmationDialog(
                    "Receipt input method",
                    isPresented: $showAddReceiptOptions
                ) {
                    Button("Take a photo") {
                        showAddReceiptOptions = false
                        showDocumentScanner = true
                    }
                    Button("Choose from gallery") {
                        showAddReceiptOptions = false
                        showPhotoLibrary = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Select input method")
                }
            }
            // Multi-select Photo picker
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
            // Document scanner view
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
            // OCR Results sheet
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
            // Clean up selection when photo picker is about to show
            .onChange(of: showPhotoLibrary) { oldValue, newValue in
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
}
