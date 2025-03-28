import SwiftUI
import PhotosUI
import VisionKit
import SwiftData

struct HomePage: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OrderItem.createdAt, order: .reverse) private var allOrders: [OrderItem]
    
    @State private var viewModel = HomeViewModel(modelContext: ModelContext(AppSchema.container))
    
    // Local UI state
    @State private var showDeleteConfirmation = false
    @State private var showAddReceiptOptions = false
    @State private var showAddProofOptions = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentScanner = false
    @State private var orderToDelete: OrderItem?
    
    init() {
        _viewModel = State(initialValue: HomeViewModel(modelContext: ModelContext(AppSchema.container)))
    }
    
    // Computed properties for filtered orders
    var filteredOrders: [OrderItem] {
        switch viewModel.currentFilter {
        case .all:
            return allOrders
        case .verified:
            return allOrders.filter { $0.verificationStatus == .verified }
        case .pending:
            return allOrders.filter { $0.verificationStatus == .pending }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    Section(header:
                                filterHeader
                        .listRowInsets(EdgeInsets())
                        .background(Material.bar)
                    ) {
                        if filteredOrders.isEmpty {
                            EmptyStateView {
                                showAddReceiptOptions = true
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(filteredOrders) { order in
                                NavigationLink(destination: OrderDetailView(order: order)) {
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
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }
                        Color.clear
                            .frame(height: 70)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                addReceiptButton
            }
            .navigationTitle("CountMe")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Delete Order",
                isPresented: $showDeleteConfirmation
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
    // Return the HomePage with the populated container
    return HomePage()
        .modelContainer(createHomePreviewContainer())
}

// Function to create a preview container with sample data specifically for HomePage
func createHomePreviewContainer() -> ModelContainer {
    // Create a schema configuration for in-memory storage
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    // Create a model container with the schema
    do {
        let container = try ModelContainer(for: OrderItem.self, configurations: config)
        
        // Add sample orders to the container
        let context = ModelContext(container)
        
        // Add sample orders
        for order in OrderItem.sampleOrders {
            context.insert(order)
        }
        
        // Add a few more orders with different dates to show variety
        let pastDate1 = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let pastDate2 = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        let pastDate3 = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        
        context.insert(OrderItem(
            title: "Udang Saus Tiram",
            dateTime: pastDate1,
            price: 55000,
            sideDishes: ["Nasi Putih 1 Porsi", "Tahu Telur", "Es Kelapa"],
            verificationStatus: .verified
        ))
        
        context.insert(OrderItem(
            title: "Sate Ayam",
            dateTime: pastDate2,
            price: 35000,
            sideDishes: ["Lontong", "Sambal Kacang"],
            verificationStatus: .pending
        ))
        
        context.insert(OrderItem(
            title: "Nasi Goreng Seafood",
            dateTime: pastDate3,
            price: 42000,
            sideDishes: ["Telur Dadar", "Kerupuk", "Es Teh"],
            verificationStatus: .verified
        ))
        
        // Create a couple more orders that are pending verification
        context.insert(OrderItem(
            title: "Mie Goreng Spesial",
            dateTime: Date().addingTimeInterval(-14400),
            price: 38500,
            sideDishes: ["Bakso 3 buah", "Pangsit Goreng"],
            verificationStatus: .pending
        ))
        
        context.insert(OrderItem(
            title: "Soto Ayam",
            dateTime: Date().addingTimeInterval(-18000),
            price: 32000,
            sideDishes: ["Nasi Putih 1 Porsi", "Emping", "Es Jeruk"],
            verificationStatus: .pending
        ))
        
        return container
    } catch {
        // If there's an error, create an empty container
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}
