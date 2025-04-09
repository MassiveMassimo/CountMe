import SwiftUI
import PhotosUI
import VisionKit
import SwiftData

struct HomePage: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OrderItem.createdAt, order: .reverse) private var allOrders: [OrderItem]
    
    @State private var viewModel = HomeViewModel(modelContext: ModelContext(AppSchema.container))
    @State private var selectedOrder: OrderItem? = nil
    
    // Local UI state
    @State private var showAddReceiptOptions = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentScanner = false
    
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
        case .mismatch:
            return allOrders.filter { $0.verificationStatus == .mismatch }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                orderListView
                addReceiptButton
            }
            .navigationTitle("CountMe")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedOrder) { order in
                OrderDetailView(order: order)
            }
            // Apply view modifiers using separate helper methods
            .applyPhotoPickerModifiers(
                showPhotoLibrary: $showPhotoLibrary,
                selectedPhotoItems: $viewModel.selectedPhotoItems,
                processSelectedPhotos: viewModel.processSelectedPhotos
            )
            .applyDocumentScannerModifiers(
                showDocumentScanner: $showDocumentScanner,
                scannedImages: $viewModel.scannedImages,
                ocrService: viewModel.ocrService,
                processScannedDocuments: viewModel.processScannedDocuments
            )
            .applyResultsSheetModifier(
                showingOCRResults: $viewModel.showingOCRResults,
                resetImageSelection: viewModel.resetImageSelection,
                images: !viewModel.scannedImages.isEmpty ? viewModel.scannedImages : viewModel.selectedImages,
                recognizedTexts: viewModel.recognizedTexts,
                viewModel: viewModel
            )
            .onChange(of: showPhotoLibrary) { oldValue, newValue in
                if newValue {
                    viewModel.selectedPhotoItems = []
                }
            }
            .overlay {
                processingOverlayView
            }
            .onAppear {
                // Update the viewModel with the environment's modelContext
                viewModel.updateModelContext(modelContext)
            }
        }
    }
    
    // MARK: - Components
    
    private var orderListView: some View {
        List {
            Section(header: filterHeader
                .listRowInsets(EdgeInsets())
                .background(Material.bar)
            ) {
                if filteredOrders.isEmpty {
                    emptyStateView
                } else {
                    ordersListContent
                }
                listFooterSpacer
            }
        }
        .listStyle(.plain)
        .animation(.default, value: filteredOrders)
        
    }
    
    private var emptyStateView: some View {
        EmptyStateView {
            showAddReceiptOptions = true
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private var ordersListContent: some View {
        ForEach(filteredOrders) { order in
            OrderListItem(order: order)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedOrder = order
                }
        }
    }
    
    private var listFooterSpacer: some View {
        Color.clear
            .frame(height: 70)
            .listRowSeparator(.hidden)
    }
    
    private var filterHeader: some View {
        VStack {
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
    
    private var processingOverlayView: some View {
        ProcessingOverlay(
            isVisible: viewModel.isProcessing,
            currentIndex: viewModel.processingIndex,
            totalCount: !viewModel.scannedImages.isEmpty
            ? viewModel.scannedImages.count
            : viewModel.selectedPhotoItems.count
        )
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

// MARK: - View Extensions for Modifiers
extension View {
    func applyPhotoPickerModifiers(
        showPhotoLibrary: Binding<Bool>,
        selectedPhotoItems: Binding<[PhotosPickerItem]>,
        processSelectedPhotos: @escaping () async -> Void
    ) -> some View {
        self.photosPicker(
            isPresented: showPhotoLibrary,
            selection: selectedPhotoItems,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItems.wrappedValue) { oldItems, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await processSelectedPhotos()
            }
        }
    }
    
    func applyDocumentScannerModifiers(
        showDocumentScanner: Binding<Bool>,
        scannedImages: Binding<[UIImage]>,
        ocrService: OCRService,
        processScannedDocuments: @escaping () async -> Void
    ) -> some View {
        self.fullScreenCover(isPresented: showDocumentScanner) {
            DocumentScannerView(
                scannedImages: scannedImages,
                ocrService: ocrService
            )
            .ignoresSafeArea()
            .onDisappear {
                if !scannedImages.wrappedValue.isEmpty {
                    Task {
                        await processScannedDocuments()
                    }
                }
            }
        }
    }
    
    func applyResultsSheetModifier(
        showingOCRResults: Binding<Bool>,
        resetImageSelection: @escaping () -> Void,
        images: [UIImage],
        recognizedTexts: [String],
        viewModel: HomeViewModel
    ) -> some View {
        self.sheet(isPresented: showingOCRResults, onDismiss: {
            resetImageSelection()
        }) {
            SegmentedResultView(
                images: images,
                recognizedTexts: recognizedTexts,
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    HomePage()
        .modelContainer(AppSchema.previewContainer)
}
