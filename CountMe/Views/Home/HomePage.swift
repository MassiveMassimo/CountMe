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
            ZStack(alignment: .bottom) {
                List {
                    // Add the filter as a section header inside the List
                    Section(header:
                                filterHeader
                        .listRowInsets(EdgeInsets())
                        .background(Material.bar)
                    ) {
                        if viewModel.filteredOrders.isEmpty {
                            EmptyStateView {
                                showAddReceiptOptions = true
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.filteredOrders) { order in
                                OrderListItem(
                                    order: order,
                                    onDelete: {
                                        orderToDelete = order
                                        showDeleteConfirmation = true
                                    },
                                    onEdit: {
                                        viewModel.editOrder(order)
                                    },
                                    onScanProof: {
                                        // Store the current order being edited
                                        viewModel.orderBeingEdited = order
                                        // Show the document scanner options dialog instead of directly opening scanner
                                        showAddReceiptOptions = true
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }
                        
                        // Add space at bottom for the floating button
                        Color.clear
                            .frame(height: 70)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                // This is crucial - it creates sticky headers when scrolling
                .environment(\.defaultMinListHeaderHeight, 0)
                
                // Floating action button
                addReceiptButton
            }
            .navigationTitle("CountMe")
            .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - View Components
    
    private var filterHeader: some View {
        VStack() {
            Picker("Filter", selection: $viewModel.currentFilter) {
                ForEach(OrderFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
        }
    }
    
    private var addReceiptButton: some View {
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
        .padding(.bottom, 8)
        .confirmationDialog(
            viewModel.orderBeingEdited != nil ? "Add proof for order" : "Receipt input method",
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
            Button("Cancel", role: .cancel) {
                // Reset orderBeingEdited if user cancels
                viewModel.orderBeingEdited = nil
            }
        } message: {
            Text(viewModel.orderBeingEdited != nil ? "Select proof input method" : "Select input method")
        }
    }
}

#Preview {
    HomePage()
}
